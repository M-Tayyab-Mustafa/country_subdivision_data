import 'dart:io';

import 'src/snapshot_validator.dart';

const _help = '''
Validate the committed country subdivision snapshot.

Usage:
  dart run tool/validate_snapshot.dart [--snapshot PATH]
  dart run tool/validate_snapshot.dart --help
''';

void main(List<String> arguments) {
  if (arguments.contains('--help')) {
    stdout.write(_help);
    return;
  }
  var path = 'assets/country_subdivision_data';
  if (arguments.length == 2 && arguments.first == '--snapshot') {
    path = arguments.last;
  } else if (arguments.isNotEmpty) {
    stderr.write(_help);
    exitCode = 64;
    return;
  }
  try {
    final result = validateSnapshot(Directory(path));
    stdout
      ..writeln('Snapshot validation passed.')
      ..writeln('Countries: ${result.countries}')
      ..writeln('Subdivisions: ${result.subdivisions}')
      ..writeln('Cities: ${result.cities}')
      ..writeln('SHA-256: ${result.sha256}')
      ..writeln('Nigeria regression: passed');
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('Snapshot validation failed: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  }
}
