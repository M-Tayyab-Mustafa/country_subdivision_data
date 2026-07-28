import 'dart:convert';

import 'package:country_subdivision_data/country_subdivision_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetCountrySubdivisionRepository', () {
    test('initialization is idempotent and shares concurrent work', () async {
      final data = CountrySubdivisionData();
      await Future.wait(<Future<void>>[data.initialize(), data.initialize()]);
      expect(data.isInitialized, isTrue);
      expect(data.snapshotMetadata.countryCount, 250);
      expect(await data.getCountries(), hasLength(250));
    });

    test('country codes are trimmed and case-insensitive', () async {
      final data = CountrySubdivisionData();
      expect((await data.getCountryByIso2(' ng '))?.iso3, 'NGA');
      expect((await data.getCountryByIso3(' nga '))?.iso2, 'NG');
      expect((await data.getCountryByCode('unknown')), isNull);
      expect(await data.getSubdivisions(countryCode: 'XX'), isEmpty);
    });

    test('loads one country lazily, caches it, and clears cache', () async {
      final data = CountrySubdivisionData();
      final first = await data.getSubdivisions(countryCode: 'NG');
      final concurrent =
          await Future.wait<List<Subdivision>>(<Future<List<Subdivision>>>[
        data.getSubdivisions(countryCode: 'ng'),
        data.getSubdivisions(countryCode: 'NG'),
      ]);
      expect(first, hasLength(37));
      expect(concurrent.first, same(concurrent.last));
      await data.clearCache();
      expect(await data.getSubdivisions(countryCode: 'NG'), hasLength(37));
    });

    test('rejects invalid cache bounds', () {
      expect(
        () => AssetCountrySubdivisionRepository(maximumCachedCountries: 0),
        throwsArgumentError,
      );
    });

    test('throws a typed format failure for malformed manifest JSON', () async {
      final repository = AssetCountrySubdivisionRepository(
        assetBundle: _FixtureBundle(<String, List<int>>{
          'fixture/manifest.json': utf8.encode('[]'),
          'fixture/countries.json': utf8.encode('[]'),
        }),
        assetPrefix: 'fixture',
      );
      await expectLater(
        repository.initialize(),
        throwsA(
          anyOf(
            isA<CountrySubdivisionInitializationException>(),
            isA<CountrySubdivisionDataFormatException>(),
          ),
        ),
      );
    });
  });
}

final class _FixtureBundle extends CachingAssetBundle {
  _FixtureBundle(this.values);

  final Map<String, List<int>> values;

  @override
  Future<ByteData> load(String key) async {
    final value = values[key];
    if (value == null) {
      throw StateError('Missing fixture $key');
    }
    return Uint8List.fromList(value).buffer.asByteData();
  }
}
