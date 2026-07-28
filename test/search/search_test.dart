import 'package:country_subdivision_data/country_subdivision_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('location search', () {
    late CountrySubdivisionData data;

    setUp(() {
      data = CountrySubdivisionData();
    });

    test('ranks exact matches before prefixes and substrings', () async {
      final results = await data.searchCities(
        query: 'Port Harcourt',
        countryCode: 'NG',
        limit: 20,
      );
      expect(results, isNotEmpty);
      expect(results.first.name, 'Port Harcourt');
    });

    test('normalizes case and surrounding/repeated whitespace', () async {
      final results = await data.searchCities(
        query: '  port   harcourt  ',
        countryCode: 'ng',
      );
      expect(results.map((city) => city.name), contains('Port Harcourt'));
    });

    test('normalizes common diacritics', () async {
      final results = await data.searchCities(
        query: 'sao paulo',
        countryCode: 'BR',
      );
      expect(results.map((city) => city.name), contains('São Paulo'));
    });

    test('empty searches are empty and invalid limits fail', () async {
      expect(
        await data.searchCountries(query: '   '),
        isEmpty,
      );
      await expectLater(
        data.searchCities(query: 'Port', limit: 0),
        throwsArgumentError,
      );
    });
  });
}
