import 'dart:async';

import 'package:country_subdivision_data/country_subdivision_data.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = CountrySubdivisionData();
  await _measure('manifest initialization', data.initialize);
  await _measure('Nigeria load', () => data.preloadCountry('NG'));
  await _measure(
    'Nigeria subdivisions',
    () => data.getSubdivisions(countryCode: 'NG'),
  );
  await _measure(
    'Rivers cities',
    () => data.getCities(countryCode: 'NG', subdivisionCode: 'RI'),
  );
  await _measure(
    'Port Harcourt search',
    () => data.searchCities(
      query: 'Port Harcourt',
      countryCode: 'NG',
      subdivisionCode: 'RI',
    ),
  );
  await _measure('cached Nigeria load', () => data.preloadCountry('NG'));
  await data.clearCache();
  await _measure('Nigeria reload after clear', () => data.preloadCountry('NG'));
}

Future<void> _measure(
  String name,
  FutureOr<Object?> Function() operation,
) async {
  final stopwatch = Stopwatch()..start();
  await operation();
  stopwatch.stop();
  // Benchmark output is intentionally the measured result.
  // ignore: avoid_print
  print('$name: ${stopwatch.elapsedMicroseconds} µs');
}
