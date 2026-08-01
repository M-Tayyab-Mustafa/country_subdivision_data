import 'package:country_subdivision_data/country_subdivision_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalized models', () {
    test(
      'Country parses nullable and malformed optional values defensively',
      () {
        final country = Country.fromJson(<String, Object?>{
          'id': 161,
          'name': 'Nigeria',
          'iso2': 'ng',
          'iso3': 'nga',
          'latitude': 'not-a-number',
          'longitude': 8.0,
          'timezones': <Object?>['Africa/Lagos', 3],
        });

        expect(country.iso2, 'NG');
        expect(country.iso3, 'NGA');
        expect(country.latitude, isNull);
        expect(country.longitude, 8);
        expect(country.timezones, <String>['Africa/Lagos']);
        expect(() => country.timezones.add('UTC'), throwsUnsupportedError);
        expect(Country.fromJson(country.toJson()), country);
        expect(country.toString(), contains('Nigeria'));
      },
    );

    test('Subdivision supports missing optional fields and value equality', () {
      final json = <String, Object?>{
        'id': 4926,
        'countryId': 161,
        'countryCode': 'NG',
        'name': 'Rivers',
        'code': 'RI',
      };
      final first = Subdivision.fromJson(json);
      final second = Subdivision.fromJson(json);
      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.type, isNull);
    });

    test('City ignores malformed optional identifier and numeric values', () {
      final city = City.fromJson(<String, Object?>{
        'id': 148552,
        'countryId': 161,
        'countryCode': 'NG',
        'subdivisionId': 'bad',
        'name': 'Port Harcourt',
        'latitude': '4.75',
        'longitude': 'bad',
      });
      expect(city.subdivisionId, isNull);
      expect(city.latitude, 4.75);
      expect(city.longitude, isNull);
      expect(City.fromJson(city.toJson()), city);
    });

    test('Snapshot metadata round-trips', () {
      final metadata =
          CountrySubdivisionSnapshotMetadata.fromJson(<String, Object?>{
            'schemaVersion': 1,
            'generatedAt': '2026-07-25T09:01:20.000Z',
            'upstreamRepository': 'dr5hn/countries-states-cities-database',
            'upstreamCommit': List<String>.filled(40, 'a').join(),
            'upstreamRelease': null,
            'countries': 250,
            'subdivisions': 5308,
            'cities': 152970,
            'sha256': List<String>.filled(64, 'b').join(),
            'generatorVersion': '1.0.0',
            'license': 'ODbL-1.0',
          });
      expect(
        CountrySubdivisionSnapshotMetadata.fromJson(metadata.toJson()),
        metadata,
      );
    });
  });
}
