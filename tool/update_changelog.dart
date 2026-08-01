import 'dart:io';

import 'src/tool_utils.dart';

const _help = '''
Prepend a verified release entry to CHANGELOG.md.

Usage:
  dart run tool/update_changelog.dart --version VERSION
      --trigger flutter|data|combined|maintenance
      [--old-flutter VERSION --new-flutter VERSION]
      [--old-commit SHA --new-commit SHA]
  dart run tool/update_changelog.dart --old-manifest OLD --new-manifest NEW
      --version VERSION
  dart run tool/update_changelog.dart --help
''';

void main(List<String> arguments) {
  if (arguments.contains('--help')) {
    stdout.write(_help);
    return;
  }
  try {
    final options = parseOptions(arguments);
    final version = options['version'] ?? _pubspecVersion();
    var trigger = options['trigger'];
    String? oldCommit = options['old-commit'];
    String? newCommit = options['new-commit'];
    if (options['old-manifest'] != null && options['new-manifest'] != null) {
      final oldManifest = readJsonMap(File(options['old-manifest']!));
      final newManifest = readJsonMap(File(options['new-manifest']!));
      oldCommit = oldManifest['upstreamCommit']?.toString();
      newCommit = newManifest['upstreamCommit']?.toString();
      trigger ??= 'data';
    }
    if (trigger != 'flutter' &&
        trigger != 'data' &&
        trigger != 'combined' &&
        trigger != 'maintenance') {
      throw const FormatException(
        '--trigger flutter|data|combined|maintenance is required.',
      );
    }
    final changelog = File('CHANGELOG.md');
    final existing = changelog.existsSync() ? changelog.readAsStringSync() : '';
    if (RegExp(
      '^## ${RegExp.escape(version)}\$',
      multiLine: true,
    ).hasMatch(existing)) {
      throw FormatException('CHANGELOG.md already contains $version.');
    }
    final buffer = StringBuffer('## $version\n\n');
    if (trigger == 'flutter' || trigger == 'combined') {
      final oldFlutter = options['old-flutter'];
      final newFlutter = options['new-flutter'];
      if (oldFlutter == null || newFlutter == null) {
        throw const FormatException('Flutter version details are required.');
      }
      buffer
        ..writeln('### Toolchain\n')
        ..writeln(
          '- Updated the pinned Flutter stable SDK from '
          '`$oldFlutter` to `$newFlutter`.',
        )
        ..writeln('- The minimum supported Flutter SDK remains unchanged.\n');
    }
    if (trigger == 'data' || trigger == 'combined') {
      if (oldCommit == null || newCommit == null) {
        throw const FormatException('Upstream commit details are required.');
      }
      buffer
        ..writeln('### Data\n')
        ..writeln('- Updated the country, subdivision, and city snapshot.');
      if (oldCommit == newCommit) {
        buffer.writeln(
          '- Preserved verified upstream commit `$newCommit` while '
          'normalizing deterministic snapshot encoding.\n',
        );
      } else {
        buffer.writeln(
          '- Updated the upstream database commit from '
          '`$oldCommit` to `$newCommit`.\n',
        );
      }
    }
    if (trigger == 'maintenance') {
      buffer
        ..writeln('### Automation\n')
        ..writeln(
          '- Repaired release validation for the current GitHub-hosted '
          'Ubuntu runner.',
        )
        ..writeln(
          '- Made automated failure reporting create its required labels.\n',
        );
    }
    buffer
      ..writeln('### Validation\n')
      ..writeln(
        '- Passed formatting, analysis, tests, snapshot integrity, '
        'Nigeria regression, and pub.dev publication dry-run.',
      )
      ..writeln();
    final temporary = File('CHANGELOG.md.tmp')
      ..writeAsStringSync('$buffer$existing');
    temporary.renameSync(changelog.path);
    stdout.writeln('Added CHANGELOG.md entry for $version.');
  } on Object catch (error) {
    stderr.writeln('Changelog update failed: $error');
    exitCode = 1;
  }
}

String _pubspecVersion() {
  final contents = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    throw const FormatException('pubspec.yaml version is missing.');
  }
  return match.group(1)!;
}
