import 'dart:io';

import 'src/semantic_version.dart';
import 'src/tool_utils.dart';

const _help = '''
Manage the package's decimal-digit rollover version policy.

Usage:
  dart run tool/version_manager.dart current
  dart run tool/version_manager.dart next
  dart run tool/version_manager.dart bump --reason flutter|data|combined|maintenance
      [--dry-run] [--skip-changelog]
  dart run tool/version_manager.dart verify [--tag vX.Y.Z]
  dart run tool/version_manager.dart --help
''';

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.contains('--help')) {
    stdout.write(_help);
    return;
  }
  try {
    final command = arguments.first;
    final options = parseOptions(
      arguments.skip(1).toList(),
      flags: <String>{'dry-run', 'skip-changelog'},
    );
    final current = _readVersion();
    switch (command) {
      case 'current':
        stdout.writeln(current);
      case 'next':
        stdout.writeln(current.nextPackageVersion);
      case 'bump':
        final reason = options['reason'];
        if (reason != 'flutter' &&
            reason != 'data' &&
            reason != 'combined' &&
            reason != 'maintenance') {
          throw const FormatException(
            'A publishable --reason '
            'flutter|data|combined|maintenance is required.',
          );
        }
        final next = current.nextPackageVersion;
        if (options.containsKey('dry-run')) {
          stdout.writeln('Dry run: $current → $next ($reason).');
          return;
        }
        _replacePubspecVersion(current, next);
        if (!options.containsKey('skip-changelog')) {
          _prependChangelog(next, reason!);
        }
        stdout.writeln('Package version updated: $current → $next.');
      case 'verify':
        _verify(current, options['tag']);
      default:
        stderr.write(_help);
        exitCode = 64;
    }
  } on Object catch (error) {
    stderr.writeln('Version manager failed: $error');
    exitCode = 1;
  }
}

SemanticVersion _readVersion() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final matches = RegExp(
    r'^version:\s*(\S+)\s*$',
    multiLine: true,
  ).allMatches(pubspec).toList();
  if (matches.length != 1) {
    throw const FormatException('pubspec.yaml must contain one version.');
  }
  return SemanticVersion.parse(
    matches.single.group(1)!,
    enforcePackagePolicy: true,
  );
}

void _replacePubspecVersion(SemanticVersion current, SemanticVersion next) {
  final file = File('pubspec.yaml');
  final updated = file.readAsStringSync().replaceFirst(
    RegExp(r'^version:\s*\S+\s*$', multiLine: true),
    'version: $next',
  );
  final temporary = File('pubspec.yaml.tmp')..writeAsStringSync(updated);
  temporary.renameSync(file.path);
}

void _prependChangelog(SemanticVersion version, String reason) {
  final file = File('CHANGELOG.md');
  final existing = file.existsSync() ? file.readAsStringSync() : '';
  final changes = <String>[
    if (reason == 'flutter' || reason == 'combined')
      '- Updated the pinned development Flutter stable version.',
    if (reason == 'data' || reason == 'combined')
      '- Updated the bundled country, subdivision, and city snapshot.',
    if (reason == 'maintenance')
      '- Repaired release automation and publication validation.',
  ];
  final temporary = File('CHANGELOG.md.tmp')
    ..writeAsStringSync('## $version\n\n${changes.join('\n')}\n\n$existing');
  temporary.renameSync(file.path);
}

void _verify(SemanticVersion version, String? explicitTag) {
  final changelog = File('CHANGELOG.md');
  if (!changelog.existsSync() ||
      !RegExp(
        '^## ${RegExp.escape(version.toString())}\$',
        multiLine: true,
      ).hasMatch(changelog.readAsStringSync())) {
    throw FormatException('CHANGELOG.md does not contain $version.');
  }
  final tag =
      explicitTag ??
      (Platform.environment['GITHUB_REF_TYPE'] == 'tag'
          ? Platform.environment['GITHUB_REF_NAME']
          : null);
  if (tag != null && tag.isNotEmpty && tag != 'v$version') {
    throw FormatException('Tag $tag does not match v$version.');
  }
  stdout.writeln('Version-policy verification passed: $version.');
}
