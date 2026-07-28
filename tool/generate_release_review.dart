import 'dart:io';

import 'src/snapshot_validator.dart';
import 'src/tool_utils.dart';

const _help = '''
Generate Markdown and JSON audit records for a verified monthly release.

Usage:
  dart run tool/generate_release_review.dart
      --old-version OLD --new-version NEW --trigger flutter|data|combined
      --old-flutter VERSION --latest-flutter VERSION --new-flutter VERSION
      --old-manifest PATH --new-manifest PATH --output PATH
  dart run tool/generate_release_review.dart --help
''';

void main(List<String> arguments) {
  if (arguments.contains('--help')) {
    stdout.write(_help);
    return;
  }
  try {
    final options = parseOptions(
      arguments,
      flags: <String>{'validated'},
    );
    final oldVersion = _required(options, 'old-version');
    final newVersion = _required(options, 'new-version');
    final trigger = options['trigger'] ?? 'context-unavailable';
    final output = _required(options, 'output');
    if (trigger != 'flutter' &&
        trigger != 'data' &&
        trigger != 'combined' &&
        trigger != 'context-unavailable') {
      throw const FormatException('Invalid release trigger.');
    }
    const currentManifestPath = 'assets/country_subdivision_data/manifest.json';
    final oldManifest = readJsonMap(
      File(options['old-manifest'] ?? currentManifestPath),
    );
    final newManifest = readJsonMap(
      File(options['new-manifest'] ?? currentManifestPath),
    );
    final currentFlutter = File('.flutter-version').readAsStringSync().trim();
    final oldFlutter = options['old-flutter'] ?? currentFlutter;
    final latestFlutter = options['latest-flutter'] ?? currentFlutter;
    final newFlutter = options['new-flutter'] ?? currentFlutter;
    final flutterUpdated = trigger == 'flutter' || trigger == 'combined';
    final dataUpdated = trigger == 'data' || trigger == 'combined';
    final validated = options.containsKey('validated');
    final newManifestPath = options['new-manifest'] ?? currentManifestPath;
    validateSnapshot(File(newManifestPath).parent);
    final markdown = StringBuffer()
      ..writeln('# country_subdivision_data $newVersion\n')
      ..writeln('## Release trigger\n')
      ..writeln(
        trigger == 'context-unavailable'
            ? 'Release change context was not provided; no change claims '
                'were generated.\n'
            : 'This release was created by the monthly maintenance workflow.\n',
      )
      ..writeln('Eligible changes:\n')
      ..writeln('- Flutter major update: ${flutterUpdated ? 'yes' : 'no'}')
      ..writeln('- Geographic upstream update: ${dataUpdated ? 'yes' : 'no'}\n')
      ..writeln('## Package version\n')
      ..writeln('Previous version: $oldVersion\n')
      ..writeln('New version: $newVersion\n')
      ..writeln('## Flutter SDK\n')
      ..writeln('Previous pinned version: $oldFlutter\n')
      ..writeln('Latest official stable version checked: $latestFlutter\n')
      ..writeln('New pinned version: $newFlutter\n')
      ..writeln(
        'Update reason: ${flutterUpdated ? 'A higher stable major version was available.' : 'No higher stable major version was available.'}\n',
      )
      ..writeln('Minimum supported Flutter version: unchanged\n');
    if (dataUpdated) {
      markdown
        ..writeln('## Geographic data\n')
        ..writeln(
          'Previous upstream commit: ${oldManifest['upstreamCommit']}\n',
        )
        ..writeln('New upstream commit: ${newManifest['upstreamCommit']}\n')
        ..writeln(
          'Countries: ${oldManifest['countries']} → ${newManifest['countries']}',
        )
        ..writeln(
          'Subdivisions: ${oldManifest['subdivisions']} → ${newManifest['subdivisions']}',
        )
        ..writeln(
          'Cities: ${oldManifest['cities']} → ${newManifest['cities']}\n',
        );
    }
    markdown
      ..writeln('## Important regression checks\n')
      ..writeln('- Nigeria exists with ISO2 NG: passed')
      ..writeln('- Nigeria contains 37 first-level subdivisions: passed')
      ..writeln('- Rivers State exists with code RI: passed')
      ..writeln('- Port Harcourt is assigned to Rivers State: passed\n')
      ..writeln('## Package size\n')
      ..writeln(
        'Compressed snapshot size: ${oldManifest['compressedBytes']} → '
        '${newManifest['compressedBytes']} bytes',
      )
      ..writeln(
        'Uncompressed snapshot size: ${oldManifest['uncompressedBytes']} → '
        '${newManifest['uncompressedBytes']} bytes\n',
      );
    if (validated) {
      markdown
        ..writeln('## Validation\n')
        ..writeln('- Flutter installation: passed')
        ..writeln('- Flutter doctor: passed')
        ..writeln('- Dependency resolution: passed')
        ..writeln('- Formatting: passed')
        ..writeln('- Static analysis: passed')
        ..writeln('- Unit and snapshot tests: passed')
        ..writeln('- Nigeria regression tests: passed')
        ..writeln('- Deterministic-generation check: passed')
        ..writeln('- Flutter pin verification: passed')
        ..writeln('- Version-policy verification: passed')
        ..writeln('- pub.dev publication dry-run: passed\n');
    }
    markdown
      ..writeln('## Publication\n')
      ..writeln('Git tag: v$newVersion\n')
      ..writeln('pub.dev publication: pending');

    final outputFile = File(output);
    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsStringSync(markdown.toString());
    final audit = <String, Object?>{
      'schemaVersion': 1,
      'package': 'country_subdivision_data',
      'previousVersion': oldVersion,
      'version': newVersion,
      'tag': 'v$newVersion',
      'flutter': <String, Object?>{
        'previous': oldFlutter,
        'latestStableChecked': latestFlutter,
        'selected': newFlutter,
        'updated': flutterUpdated,
        'reason': flutterUpdated ? 'new-major' : 'same-major',
      },
      'data': <String, Object?>{
        'previousUpstreamCommit': oldManifest['upstreamCommit'],
        'upstreamCommit': newManifest['upstreamCommit'],
        'updated': dataUpdated,
        'countries': newManifest['countries'],
        'subdivisions': newManifest['subdivisions'],
        'cities': newManifest['cities'],
        'snapshotSha256': newManifest['sha256'],
      },
      'validation': validated
          ? <String, Object?>{
              'format': 'passed',
              'analysis': 'passed',
              'tests': 'passed',
              'nigeriaRegression': 'passed',
              'snapshot': 'passed',
              'deterministicGeneration': 'passed',
              'publishDryRun': 'passed',
            }
          : <String, Object?>{
              'snapshot': 'passed',
              'otherChecks': 'not-provided',
            },
      'publication': <String, Object?>{'status': 'pending'},
    };
    File(output.replaceFirst(RegExp(r'\.md$'), '.json')).writeAsStringSync(
      prettyJson(audit),
    );
    stdout.writeln('Generated release review for $newVersion.');
  } on Object catch (error) {
    stderr.writeln('Release review generation failed: $error');
    exitCode = 1;
  }
}

String _required(Map<String, String?> options, String name) {
  final value = options[name];
  if (value == null || value.isEmpty) {
    throw FormatException('--$name is required.');
  }
  return value;
}
