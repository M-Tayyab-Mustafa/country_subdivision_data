import 'package:country_subdivision_data/country_subdivision_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Nigeria regression', () {
    late CountrySubdivisionData data;

    setUpAll(() async {
      data = CountrySubdivisionData();
      await data.initialize();
    });

    test('Nigeria has the expected country identity', () async {
      final iso2 = await data.getCountryByCode('NG');
      final iso3 = await data.getCountryByCode('NGA');
      expect(iso2?.iso3, 'NGA');
      expect(iso3?.iso2, 'NG');
    });

    test('Nigeria has 36 states and the Federal Capital Territory', () async {
      final subdivisions = await data.getSubdivisions(countryCode: 'ng');
      expect(subdivisions, hasLength(37));
      expect(
        subdivisions.where(
          (value) => value.name.contains('Federal Capital Territory'),
        ),
        hasLength(1),
      );
    });

    test('Rivers and Port Harcourt retain their relationship', () async {
      final rivers = await data.getSubdivisionByCode(
        countryCode: 'ng',
        subdivisionCode: 'ri',
      );
      expect(rivers, isNotNull);
      expect(rivers!.name, 'Rivers');
      expect(rivers.countryCode, 'NG');

      final cities = await data.getCities(
        countryCode: 'NG',
        subdivisionCode: 'RI',
      );
      final portHarcourt = cities.where((city) => city.name == 'Port Harcourt');
      expect(cities, isNotEmpty);
      expect(portHarcourt, hasLength(1));
      expect(portHarcourt.single.subdivisionId, rivers.id);
      expect(portHarcourt.single.countryCode, 'NG');
    });

    test('Port Harcourt search is case and whitespace insensitive', () async {
      for (final query in <String>[
        'Port Harcourt',
        'port harcourt',
        '  port   harcourt ',
      ]) {
        final result = await data.searchCities(
          query: query,
          countryCode: 'NG',
          subdivisionCode: 'ri',
        );
        expect(result.map((city) => city.name), contains('Port Harcourt'));
      }
    });
  });
}
