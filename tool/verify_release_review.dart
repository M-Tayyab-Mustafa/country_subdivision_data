import 'dart:convert';
import 'dart:io';

const _help = '''
Verify the release review committed for the current package version.

The initial 0.0.1 source release is allowed to have no generated review.
Every later version must include matching Markdown and JSON audit records.

Usage:
  dart run tool/verify_release_review.dart
  dart run tool/verify_release_review.dart --help
''';

void main(List<String> arguments) {
  if (arguments.contains('--help')) {
    stdout.write(_help);
    return;
  }
  try {
    if (arguments.isNotEmpty) {
      throw const FormatException('Unexpected arguments.');
    }
    final version = _packageVersion();
    final markdownFile = File('tool/reports/releases/$version.md');
    final jsonFile = File('tool/reports/releases/$version.json');
    if (version == '0.0.1' &&
        !markdownFile.existsSync() &&
        !jsonFile.existsSync()) {
      stdout.writeln('Release-review verification passed for initial 0.0.1.');
      return;
    }
    if (!markdownFile.existsSync() || !jsonFile.existsSync()) {
      throw FormatException(
        'Both release review files are required for version $version.',
      );
    }

    final markdown = markdownFile.readAsStringSync();
    final changelog = File('CHANGELOG.md').readAsStringSync();
    final manifest = _readJson(
      File('assets/country_subdivision_data/manifest.json'),
    );
    final review = _readJson(jsonFile);
    final validation = _map(review['validation'], 'validation');
    final data = _map(review['data'], 'data');

    _expect(review['package'] == 'country_subdivision_data', 'package');
    _expect(review['version'] == version, 'version');
    _expect(review['tag'] == 'v$version', 'tag');
    _expect(
      RegExp(
        '^# country_subdivision_data ${RegExp.escape(version)}\$',
        multiLine: true,
      ).hasMatch(markdown),
      'Markdown heading',
    );
    _expect(markdown.contains('Git tag: v$version'), 'Markdown tag');
    _expect(
      RegExp(
        '^## ${RegExp.escape(version)}\$',
        multiLine: true,
      ).hasMatch(changelog),
      'changelog heading',
    );
    _expect(
      data['upstreamCommit'] == manifest['upstreamCommit'],
      'upstream commit',
    );
    _expect(data['snapshotSha256'] == manifest['sha256'], 'snapshot checksum');
    const requiredValidations = <String>[
      'format',
      'analysis',
      'tests',
      'nigeriaRegression',
      'snapshot',
      'deterministicGeneration',
      'flutterSdk',
      'upstreamMetadata',
      'versionPolicy',
      'releaseReview',
      'publishDryRun',
    ];
    for (final check in requiredValidations) {
      _expect(validation[check] == 'passed', 'validation.$check');
    }
    stdout.writeln('Release-review verification passed: $version.');
  } on Object catch (error) {
    stderr.writeln('Release-review verification failed: $error');
    exitCode = 1;
  }
}

String _packageVersion() {
  final match = RegExp(
    r'^version:\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(File('pubspec.yaml').readAsStringSync());
  if (match == null) {
    throw const FormatException('pubspec.yaml version is missing.');
  }
  return match.group(1)!;
}

Map<String, Object?> _readJson(File file) {
  final value = jsonDecode(file.readAsStringSync());
  return _map(value, file.path);
}

Map<String, Object?> _map(Object? value, String field) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$field must be a JSON object.');
  }
  return value;
}

void _expect(bool condition, String field) {
  if (!condition) {
    throw FormatException('$field does not match the release.');
  }
}
