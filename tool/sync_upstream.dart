import 'dart:io';

import 'src/snapshot_generator.dart';
import 'src/tool_utils.dart';

const _help = '''
Synchronize the snapshot from a verified upstream checkout.

Usage:
  dart run tool/sync_upstream.dart [--upstream-path PATH]
      [--upstream-commit SHA] [--output PATH]
  dart run tool/sync_upstream.dart --help

Without --upstream-path, the tool explicitly downloads a shallow temporary
checkout from dr5hn/countries-states-cities-database.
''';

void main(List<String> arguments) {
  if (arguments.contains('--help')) {
    stdout.write(_help);
    return;
  }
  Directory? temporary;
  try {
    final options = parseOptions(arguments);
    var upstreamPath = options['upstream-path'];
    if (upstreamPath == null) {
      temporary = Directory.systemTemp.createTempSync(
        'country-subdivision-upstream-',
      );
      final checkout = Directory('${temporary.path}/upstream');
      final result = Process.runSync('git', <String>[
        'clone',
        '--depth',
        '1',
        'https://github.com/dr5hn/countries-states-cities-database.git',
        checkout.path,
      ]);
      if (result.exitCode != 0) {
        throw StateError('Upstream clone failed: ${result.stderr}');
      }
      upstreamPath = checkout.path;
    }
    final result = generateSnapshot(
      upstream: Directory(upstreamPath),
      output: Directory(
        options['output'] ?? 'assets/country_subdivision_data',
      ),
      expectedCommit: options['upstream-commit'],
    );
    stdout.writeln(
      'Synchronized ${result.countryCount} countries from '
      '${result.upstreamCommit}.',
    );
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('Upstream synchronization failed: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  } finally {
    temporary?.deleteSync(recursive: true);
  }
}
