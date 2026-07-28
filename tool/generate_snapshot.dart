import 'dart:io';

import 'src/snapshot_generator.dart';
import 'src/tool_utils.dart';

const _help = '''
Generate the deterministic country subdivision snapshot.

Usage:
  dart run tool/generate_snapshot.dart --upstream-path PATH
      [--output PATH] [--upstream-commit SHA]
  dart run tool/generate_snapshot.dart --help
''';

void main(List<String> arguments) {
  if (arguments.contains('--help')) {
    stdout.write(_help);
    return;
  }
  try {
    final options = parseOptions(arguments);
    final upstreamPath = options['upstream-path'];
    if (upstreamPath == null) {
      throw const FormatException('--upstream-path is required.');
    }
    final output = options['output'] ?? 'assets/country_subdivision_data';
    final result = generateSnapshot(
      upstream: Directory(upstreamPath),
      output: Directory(output),
      expectedCommit: options['upstream-commit'],
    );
    stdout
      ..writeln('Generated snapshot from ${result.upstreamCommit}.')
      ..writeln('Countries: ${result.countryCount}')
      ..writeln('Subdivisions: ${result.subdivisionCount}')
      ..writeln('Cities: ${result.cityCount}')
      ..writeln('SHA-256: ${result.snapshotSha256}')
      ..writeln('Compressed bytes: ${result.compressedBytes}')
      ..writeln('Uncompressed bytes: ${result.uncompressedBytes}');
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('Snapshot generation failed: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  }
}
