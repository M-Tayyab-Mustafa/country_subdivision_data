import 'dart:convert';
import 'dart:io';

import 'src/semantic_version.dart';
import 'src/tool_utils.dart';

const _metadataUrl =
    'https://storage.googleapis.com/flutter_infra_release/releases/'
    'releases_macos.json';

const _help = '''
Manage the repository's exact official stable Flutter pin.

Usage:
  dart run tool/flutter_sdk_manager.dart current
  dart run tool/flutter_sdk_manager.dart latest [--metadata FILE|URL]
  dart run tool/flutter_sdk_manager.dart check [--metadata FILE|URL]
  dart run tool/flutter_sdk_manager.dart update [--metadata FILE|URL] [--dry-run]
  dart run tool/flutter_sdk_manager.dart verify
  dart run tool/flutter_sdk_manager.dart --help
''';

void main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.contains('--help')) {
    stdout.write(_help);
    return;
  }
  final command = arguments.first;
  final options = parseOptions(
    arguments.skip(1).toList(),
    flags: <String>{'dry-run'},
  );
  try {
    switch (command) {
      case 'current':
        _current();
      case 'latest':
        final release = await _latest(options['metadata']);
        _printRelease(release);
      case 'check':
        final pinned = _pinned();
        final latest = await _latest(options['metadata']);
        _printComparison(pinned, latest);
        if (latest.version.compareTo(pinned) > 0) {
          exitCode = 10;
        }
      case 'update':
        final pinned = _pinned();
        final latest = await _latest(options['metadata']);
        if (latest.version.compareTo(pinned) <= 0) {
          stdout.writeln('No newer stable Flutter release; no files changed.');
          return;
        }
        if (options.containsKey('dry-run')) {
          stdout.writeln('Dry run: would update $pinned to ${latest.version}.');
          return;
        }
        _writePin(latest);
        stdout.writeln('Updated Flutter pin: $pinned → ${latest.version}.');
      case 'verify':
        _verify();
      default:
        stderr.write(_help);
        exitCode = 64;
    }
  } on FormatException catch (error) {
    stderr.writeln(error);
    exitCode = 20;
  } on SocketException catch (error) {
    stderr.writeln('Flutter metadata network failure: $error');
    exitCode = 30;
  } on HttpException catch (error) {
    stderr.writeln('Flutter metadata request failed: $error');
    exitCode = 30;
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('Flutter SDK manager failed: $error')
      ..writeln(stackTrace);
    exitCode = 40;
  }
}

void _current() {
  final pinned = _pinned();
  SemanticVersion? installed;
  try {
    final result = Process.runSync('flutter', <String>[
      '--version',
      '--machine',
    ]);
    if (result.exitCode == 0) {
      final json = jsonDecode(result.stdout.toString());
      if (json is Map<Object?, Object?> && json['frameworkVersion'] is String) {
        installed = SemanticVersion.parse(json['frameworkVersion']! as String);
      }
    }
  } on Object {
    // The installed SDK is informational; the repository pin remains usable.
  }
  stdout
    ..writeln('Pinned Flutter: $pinned')
    ..writeln('Installed Flutter: ${installed ?? 'unavailable'}')
    ..writeln('Installed matches pin: ${installed == pinned ? 'yes' : 'no'}');
}

SemanticVersion _pinned() {
  final file = File('.flutter-version');
  if (!file.existsSync()) {
    throw const FormatException('.flutter-version is missing.');
  }
  return SemanticVersion.parse(file.readAsStringSync().trim());
}

Future<_FlutterRelease> _latest(String? source) async {
  final effectiveSource = source ??
      Platform.environment['FLUTTER_RELEASE_METADATA'] ??
      _metadataUrl;
  late String contents;
  final uri = Uri.tryParse(effectiveSource);
  if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      contents = await utf8.decoder.bind(response).join();
    } finally {
      client.close();
    }
  } else {
    contents = File(effectiveSource).readAsStringSync();
  }
  final root = jsonDecode(contents);
  if (root is! Map<Object?, Object?>) {
    throw const FormatException('Malformed Flutter release metadata.');
  }
  final current = root['current_release'];
  final releases = root['releases'];
  if (current is! Map<Object?, Object?> ||
      current['stable'] is! String ||
      releases is! List<Object?>) {
    throw const FormatException('Stable Flutter release metadata is missing.');
  }
  final stableHash = current['stable']! as String;
  for (final value in releases) {
    if (value is Map<Object?, Object?> && value['hash'] == stableHash) {
      final versionText = value['version'];
      if (value['channel'] != 'stable' || versionText is! String) {
        throw const FormatException('Current Flutter release is not stable.');
      }
      final version = SemanticVersion.parse(versionText);
      return _FlutterRelease(
        version: version,
        hash: stableHash,
        releaseDate: DateTime.parse(value['release_date']! as String).toUtc(),
      );
    }
  }
  throw const FormatException('The stable Flutter release was not found.');
}

void _printRelease(_FlutterRelease release) {
  stdout
    ..writeln('Latest stable Flutter: ${release.version}')
    ..writeln('Release hash: ${release.hash}')
    ..writeln('Release date: ${release.releaseDate.toIso8601String()}');
}

void _printComparison(SemanticVersion pinned, _FlutterRelease latest) {
  final update = latest.version.compareTo(pinned) > 0;
  stdout
    ..writeln('Pinned: $pinned')
    ..writeln('Latest: ${latest.version}')
    ..writeln('Action: ${update ? 'update' : 'ignore'}');
}

void _writePin(_FlutterRelease release) {
  final pinTemporary = File('.flutter-version.tmp')
    ..writeAsStringSync('${release.version}\n');
  final metadataTemporary = File('tool/config/flutter_sdk.json.tmp')
    ..writeAsStringSync(
      prettyJson(<String, Object?>{
        'schemaVersion': 1,
        'channel': 'stable',
        'pinnedVersion': release.version.toString(),
        'releaseHash': release.hash,
        'releaseDate': release.releaseDate.toIso8601String().split('T').first,
        'checkedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  pinTemporary.renameSync('.flutter-version');
  metadataTemporary.renameSync('tool/config/flutter_sdk.json');
}

void _verify() {
  final pinned = _pinned();
  final metadata = readJsonMap(File('tool/config/flutter_sdk.json'));
  if (metadata['schemaVersion'] != 1 ||
      metadata['channel'] != 'stable' ||
      metadata['pinnedVersion'] != pinned.toString() ||
      !RegExp(r'^[0-9a-f]{40}$').hasMatch(metadata['releaseHash'].toString())) {
    throw const FormatException('Flutter SDK metadata does not match the pin.');
  }
  final workflows = Directory('.github/workflows');
  if (!workflows.existsSync()) {
    throw const FormatException('GitHub workflows are missing.');
  }
  for (final file in workflows.listSync().whereType<File>()) {
    final contents = file.readAsStringSync();
    if (RegExp(
      r'flutter-version:\s*(latest|beta|dev|master|main)\b',
      caseSensitive: false,
    ).hasMatch(contents)) {
      throw FormatException('${file.path} uses a forbidden Flutter pin.');
    }
    if (contents.contains('subosito/flutter-action')) {
      throw FormatException(
        '${file.path} bypasses the repository Flutter setup action.',
      );
    }
  }
  final setupAction = File('.github/actions/setup-flutter/action.yml');
  if (!setupAction.existsSync()) {
    throw const FormatException(
        'The repository Flutter setup action is missing.');
  }
  final setupContents = setupAction.readAsStringSync();
  for (final required in <String>[
    'subosito/flutter-action@v2',
    "< .flutter-version",
    r'flutter-version: ${{ steps.pin.outputs.version }}',
    'channel: stable',
  ]) {
    if (!setupContents.contains(required)) {
      throw const FormatException(
        'The repository Flutter setup action does not use the exact stable pin.',
      );
    }
  }
  final installed = Process.runSync('flutter', <String>[
    '--version',
    '--machine',
  ]);
  if (installed.exitCode == 0) {
    final value = jsonDecode(installed.stdout.toString());
    if (value is Map<Object?, Object?> &&
        value['frameworkVersion'] is String &&
        SemanticVersion.parse(value['frameworkVersion']! as String) != pinned) {
      throw const FormatException(
        'The installed Flutter SDK does not match .flutter-version.',
      );
    }
  }
  stdout.writeln('Flutter pin verification passed: $pinned stable.');
}

final class _FlutterRelease {
  const _FlutterRelease({
    required this.version,
    required this.hash,
    required this.releaseDate,
  });

  final SemanticVersion version;
  final String hash;
  final DateTime releaseDate;
}
