import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/snapshot_validator.dart';

void main() {
  test('committed production snapshot passes full integrity validation', () {
    final result = validateSnapshot(
      Directory('assets/country_subdivision_data'),
    );
    expect(result.countries, greaterThanOrEqualTo(249));
    expect(result.subdivisions, greaterThan(5000));
    expect(result.cities, greaterThan(150000));
    expect(result.sha256, hasLength(64));
  });

  test('gzip headers do not encode the generator operating system', () {
    final countryFiles = Directory(
      'assets/country_subdivision_data/countries',
    ).listSync().whereType<File>();
    expect(countryFiles, isNotEmpty);
    for (final file in countryFiles) {
      final header = file.openSync()..setPositionSync(0);
      try {
        final bytes = header.readSync(10);
        expect(bytes, hasLength(10), reason: file.path);
        expect(bytes[0], 0x1f, reason: file.path);
        expect(bytes[1], 0x8b, reason: file.path);
        expect(bytes[9], 255, reason: file.path);
      } finally {
        header.closeSync();
      }
    }
  });
}
