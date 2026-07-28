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
}
