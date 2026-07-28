import 'dart:io';

import 'src/snapshot_generator.dart';
import 'src/snapshot_validator.dart';
import 'src/tool_utils.dart';

const _repositoryUrl =
    'https://github.com/dr5hn/countries-states-cities-database.git';

const _help = '''
Check, update, or verify upstream geographic data.

Usage:
  dart run tool/upstream_data_manager.dart check
  dart run tool/upstream_data_manager.dart update [--dry-run]
      [--upstream-path PATH]
  dart run tool/upstream_data_manager.dart verify
  dart run tool/upstream_data_manager.dart --help

Exit codes for check:
  0 current, 10 update available, 20 invalid manifest,
  30 upstream access failure, 40 unsupported upstream structure.
''';

void main(List<String> arguments) {
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
      case 'check':
        final current = _currentCommit();
        final latest = _latestCommit();
        stdout
          ..writeln('Current upstream commit: $current')
          ..writeln('Latest upstream commit: $latest');
        if (current != latest) {
          stdout.writeln('Update available.');
          exitCode = 10;
        } else {
          stdout.writeln('Upstream data is current.');
        }
      case 'verify':
        final result = validateSnapshot(
          Directory('assets/country_subdivision_data'),
        );
        stdout.writeln(
          'Upstream snapshot verification passed: '
          '${result.countries}/${result.subdivisions}/${result.cities}.',
        );
      case 'update':
        _update(options);
      default:
        stderr.write(_help);
        exitCode = 64;
    }
  } on FormatException catch (error) {
    stderr.writeln('Invalid local manifest: $error');
    exitCode = 20;
  } on SocketException catch (error) {
    stderr.writeln('Upstream access failed: $error');
    exitCode = 30;
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('Upstream manager failed: $error')
      ..writeln(stackTrace);
    exitCode = command == 'check' ? 30 : 40;
  }
}

String _currentCommit() {
  final manifest = readJsonMap(
    File('assets/country_subdivision_data/manifest.json'),
  );
  final commit = text(manifest['upstreamCommit'], 'upstreamCommit');
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(commit)) {
    throw const FormatException('Invalid upstream commit.');
  }
  return commit;
}

String _latestCommit() {
  final result = Process.runSync('git', <String>[
    'ls-remote',
    _repositoryUrl,
    'HEAD',
  ]);
  if (result.exitCode != 0) {
    throw SocketException(result.stderr.toString());
  }
  final commit = result.stdout.toString().trim().split(RegExp(r'\s+')).first;
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(commit)) {
    throw const FormatException('Upstream HEAD did not resolve to a full SHA.');
  }
  return commit;
}

void _update(Map<String, String?> options) {
  Directory? temporary;
  try {
    var upstreamPath = options['upstream-path'];
    if (upstreamPath == null) {
      temporary = Directory.systemTemp.createTempSync(
        'country-subdivision-update-',
      );
      final checkout = '${temporary.path}/upstream';
      final clone = Process.runSync('git', <String>[
        'clone',
        '--depth',
        '1',
        _repositoryUrl,
        checkout,
      ]);
      if (clone.exitCode != 0) {
        throw SocketException(clone.stderr.toString());
      }
      upstreamPath = checkout;
    }
    if (options.containsKey('dry-run')) {
      temporary ??= Directory.systemTemp.createTempSync(
        'country-subdivision-dry-run-',
      );
      final candidate = Directory('${temporary.path}/candidate');
      final result = generateSnapshot(
        upstream: Directory(upstreamPath),
        output: candidate,
      );
      final current = readJsonMap(
        File('assets/country_subdivision_data/manifest.json'),
      );
      stdout
        ..writeln('Dry run; committed assets were not changed.')
        ..writeln('Current SHA-256: ${current['sha256']}')
        ..writeln('Candidate SHA-256: ${result.snapshotSha256}')
        ..writeln(
          'Publishable data changed: '
          '${current['sha256'] == result.snapshotSha256 ? 'no' : 'yes'}',
        );
      return;
    }
    final result = generateSnapshot(
      upstream: Directory(upstreamPath),
      output: Directory('assets/country_subdivision_data'),
    );
    stdout.writeln('Updated snapshot to ${result.upstreamCommit}.');
  } finally {
    temporary?.deleteSync(recursive: true);
  }
}
