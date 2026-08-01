import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../exceptions/country_subdivision_asset_exception.dart';
import '../exceptions/country_subdivision_data_format_exception.dart';
import '../exceptions/country_subdivision_initialization_exception.dart';
import '../models/city.dart';
import '../models/country.dart';
import '../models/country_subdivision_snapshot_metadata.dart';
import '../models/subdivision.dart';
import '../search/location_search.dart';
import 'country_subdivision_repository.dart';

const _defaultPrefix =
    'packages/country_subdivision_data/assets/country_subdivision_data';

/// Repository backed by the package's lazily loaded compressed assets.
final class AssetCountrySubdivisionRepository
    implements CountrySubdivisionRepository {
  /// Creates an asset repository.
  ///
  /// [assetBundle] and [assetPrefix] are injectable for tests and applications
  /// that intentionally repackage the generated snapshot.
  AssetCountrySubdivisionRepository({
    AssetBundle? assetBundle,
    String assetPrefix = _defaultPrefix,
    int maximumCachedCountries = 8,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _assetPrefix = assetPrefix.replaceFirst(RegExp(r'/$'), ''),
       _maximumCachedCountries = maximumCachedCountries {
    if (maximumCachedCountries <= 0) {
      throw ArgumentError.value(
        maximumCachedCountries,
        'maximumCachedCountries',
        'must be positive',
      );
    }
  }

  final AssetBundle _assetBundle;
  final String _assetPrefix;
  final int _maximumCachedCountries;
  final LinkedHashMap<String, _CountryDataset> _cache =
      LinkedHashMap<String, _CountryDataset>();
  final Map<String, Future<_CountryDataset>> _inProgress =
      <String, Future<_CountryDataset>>{};

  List<Country>? _countries;
  Map<String, Country>? _countriesByIso2;
  Map<String, Country>? _countriesByIso3;
  CountrySubdivisionSnapshotMetadata? _metadata;
  Future<void>? _initialization;

  @override
  bool get isInitialized => _metadata != null;

  @override
  CountrySubdivisionSnapshotMetadata get snapshotMetadata {
    final metadata = _metadata;
    if (metadata == null) {
      throw StateError('Call initialize() before reading snapshotMetadata.');
    }
    return metadata;
  }

  @override
  Future<void> initialize() {
    if (isInitialized) {
      return Future<void>.value();
    }
    return _initialization ??= _initialize().whenComplete(() {
      if (!isInitialized) {
        _initialization = null;
      }
    });
  }

  Future<void> _initialize() async {
    final manifestAsset = '$_assetPrefix/manifest.json';
    final countriesAsset = '$_assetPrefix/countries.json';
    try {
      final values = await Future.wait(<Future<String>>[
        _assetBundle.loadString(manifestAsset),
        _assetBundle.loadString(countriesAsset),
      ]);
      final manifest = _decodeMap(values[0], manifestAsset);
      final countryJson = _decodeList(values[1], countriesAsset);
      final metadata = CountrySubdivisionSnapshotMetadata.fromJson(manifest);
      if (metadata.schemaVersion != 1) {
        throw CountrySubdivisionDataFormatException(
          'Unsupported snapshot schema ${metadata.schemaVersion}.',
          asset: manifestAsset,
        );
      }
      final countries = countryJson
          .map((value) => Country.fromJson(_asMap(value, countriesAsset)))
          .toList(growable: false);
      if (countries.length != metadata.countryCount) {
        throw CountrySubdivisionDataFormatException(
          'Country count does not match the snapshot manifest.',
          asset: countriesAsset,
        );
      }
      _countries = List<Country>.unmodifiable(countries);
      _countriesByIso2 = <String, Country>{
        for (final country in countries) country.iso2: country,
      };
      _countriesByIso3 = <String, Country>{
        for (final country in countries) country.iso3: country,
      };
      _metadata = metadata;
    } on CountrySubdivisionDataFormatException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw CountrySubdivisionInitializationException(
        'Could not load the bundled country manifest.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Country>> getCountries() async {
    await initialize();
    return _countries!;
  }

  @override
  Future<Country?> getCountryByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.length == 2) {
      return getCountryByIso2(normalized);
    }
    if (normalized.length == 3) {
      return getCountryByIso3(normalized);
    }
    return null;
  }

  @override
  Future<Country?> getCountryByIso2(String iso2) async {
    await initialize();
    return _countriesByIso2![iso2.trim().toUpperCase()];
  }

  @override
  Future<Country?> getCountryByIso3(String iso3) async {
    await initialize();
    return _countriesByIso3![iso3.trim().toUpperCase()];
  }

  @override
  Future<List<Subdivision>> getSubdivisions({
    required String countryCode,
  }) async {
    final dataset = await _loadOrNull(countryCode);
    return dataset?.subdivisions ?? const <Subdivision>[];
  }

  @override
  Future<Subdivision?> getSubdivisionByCode({
    required String countryCode,
    required String subdivisionCode,
  }) async {
    final dataset = await _loadOrNull(countryCode);
    return dataset?.subdivisionsByCode[subdivisionCode.trim().toUpperCase()];
  }

  @override
  Future<Subdivision?> getSubdivisionById(int id) async {
    await initialize();
    for (final country in _countries!) {
      final value = (await _load(country.iso2)).subdivisionsById[id];
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  @override
  Future<List<City>> getCities({
    required String countryCode,
    String? subdivisionCode,
  }) async {
    final dataset = await _loadOrNull(countryCode);
    if (dataset == null) {
      return const <City>[];
    }
    if (subdivisionCode == null) {
      return dataset.cities;
    }
    final normalized = subdivisionCode.trim().toUpperCase();
    return dataset.citiesBySubdivisionCode[normalized] ?? const <City>[];
  }

  @override
  Future<City?> getCityById(int id) async {
    await initialize();
    for (final country in _countries!) {
      final value = (await _load(country.iso2)).citiesById[id];
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  @override
  Future<List<Country>> searchCountries({
    required String query,
    int limit = 20,
  }) async {
    final countries = await getCountries();
    return rankedLocationSearch<Country>(
      values: countries,
      query: query,
      name: (country) => country.name,
      aliases: (country) => <String>[country.iso2, country.iso3],
      limit: limit,
    );
  }

  @override
  Future<List<Subdivision>> searchSubdivisions({
    required String query,
    String? countryCode,
    int limit = 20,
  }) async {
    _validateLimit(limit);
    final values = <Subdivision>[];
    if (countryCode != null) {
      values.addAll(await getSubdivisions(countryCode: countryCode));
    } else {
      await initialize();
      for (final country in _countries!) {
        values.addAll((await _load(country.iso2)).subdivisions);
      }
    }
    return rankedLocationSearch<Subdivision>(
      values: values,
      query: query,
      name: (subdivision) => subdivision.name,
      aliases: (subdivision) => <String>[
        if (subdivision.code != null) subdivision.code!,
      ],
      limit: limit,
    );
  }

  @override
  Future<List<City>> searchCities({
    required String query,
    String? countryCode,
    String? subdivisionCode,
    int limit = 20,
  }) async {
    _validateLimit(limit);
    final values = <City>[];
    if (countryCode != null) {
      values.addAll(
        await getCities(
          countryCode: countryCode,
          subdivisionCode: subdivisionCode,
        ),
      );
    } else {
      await initialize();
      for (final country in _countries!) {
        values.addAll((await _load(country.iso2)).cities);
      }
    }
    return rankedLocationSearch<City>(
      values: values,
      query: query,
      name: (city) => city.name,
      limit: limit,
    );
  }

  @override
  Future<void> preloadCountry(String countryCode) async {
    if (await _loadOrNull(countryCode) == null) {
      return;
    }
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
    await Future.wait<void>(
      _inProgress.values.map((future) async {
        await future;
      }),
    );
    _cache.clear();
  }

  Future<_CountryDataset?> _loadOrNull(String code) async {
    await initialize();
    final normalized = code.trim().toUpperCase();
    if (!_countriesByIso2!.containsKey(normalized)) {
      return null;
    }
    return _load(normalized);
  }

  Future<_CountryDataset> _load(String countryCode) {
    final cached = _cache.remove(countryCode);
    if (cached != null) {
      _cache[countryCode] = cached;
      return Future<_CountryDataset>.value(cached);
    }
    return _inProgress[countryCode] ??= _loadAsset(countryCode).whenComplete(
      () {
        unawaited(_inProgress.remove(countryCode));
      },
    );
  }

  Future<_CountryDataset> _loadAsset(String countryCode) async {
    final asset = '$_assetPrefix/countries/$countryCode.json.gz';
    try {
      final byteData = await _assetBundle.load(asset);
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final decoded = await compute(_decodeCompressedDataset, bytes);
      if (decoded['countryCode'] != countryCode) {
        throw const FormatException('Country asset code mismatch.');
      }
      final dataset = _CountryDataset.fromJson(decoded);
      _cache[countryCode] = dataset;
      while (_cache.length > _maximumCachedCountries) {
        _cache.remove(_cache.keys.first);
      }
      return dataset;
    } on CountrySubdivisionDataFormatException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      throw CountrySubdivisionDataFormatException(
        'Country asset contains invalid normalized data.',
        asset: asset,
        countryCode: countryCode,
        cause: error,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      throw CountrySubdivisionAssetException(
        'Could not load the compressed country asset.',
        asset: asset,
        countryCode: countryCode,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

Map<String, Object?> _decodeCompressedDataset(Uint8List bytes) {
  final decompressed = GZipDecoder().decodeBytes(bytes);
  return _decodeMap(utf8.decode(decompressed), 'compressed country asset');
}

Map<String, Object?> _decodeMap(String source, String asset) {
  final decoded = jsonDecode(source);
  return _asMap(decoded, asset);
}

List<Object?> _decodeList(String source, String asset) {
  final decoded = jsonDecode(source);
  if (decoded is! List<Object?>) {
    throw FormatException('Expected a JSON array in $asset.');
  }
  return decoded;
}

Map<String, Object?> _asMap(Object? value, String asset) {
  if (value is! Map<Object?, Object?>) {
    throw FormatException('Expected a JSON object in $asset.');
  }
  return value.map(
    (key, item) => MapEntry<String, Object?>(key.toString(), item),
  );
}

void _validateLimit(int limit) {
  if (limit <= 0) {
    throw ArgumentError.value(limit, 'limit', 'must be positive');
  }
}

final class _CountryDataset {
  _CountryDataset({
    required List<Subdivision> subdivisions,
    required List<City> cities,
  }) : subdivisions = List<Subdivision>.unmodifiable(subdivisions),
       cities = List<City>.unmodifiable(cities),
       subdivisionsByCode =
           Map<String, Subdivision>.unmodifiable(<String, Subdivision>{
             for (final value in subdivisions)
               if (value.code != null) value.code!.toUpperCase(): value,
           }),
       subdivisionsById = Map<int, Subdivision>.unmodifiable(<int, Subdivision>{
         for (final value in subdivisions) value.id: value,
       }),
       citiesById = Map<int, City>.unmodifiable(<int, City>{
         for (final value in cities) value.id: value,
       }),
       citiesBySubdivisionCode = _groupCities(cities);

  factory _CountryDataset.fromJson(Map<String, Object?> json) {
    final subdivisionJson = json['subdivisions'];
    final cityJson = json['cities'];
    if (subdivisionJson is! List<Object?> || cityJson is! List<Object?>) {
      throw const FormatException(
        'Country data requires subdivisions and cities arrays.',
      );
    }
    return _CountryDataset(
      subdivisions: subdivisionJson
          .map((value) => Subdivision.fromJson(_asMap(value, 'subdivision')))
          .toList(growable: false),
      cities: cityJson
          .map((value) => City.fromJson(_asMap(value, 'city')))
          .toList(growable: false),
    );
  }

  final List<Subdivision> subdivisions;
  final List<City> cities;
  final Map<String, Subdivision> subdivisionsByCode;
  final Map<int, Subdivision> subdivisionsById;
  final Map<int, City> citiesById;
  final Map<String, List<City>> citiesBySubdivisionCode;
}

Map<String, List<City>> _groupCities(List<City> cities) {
  final grouped = <String, List<City>>{};
  for (final city in cities) {
    final code = city.subdivisionCode?.toUpperCase();
    if (code != null) {
      (grouped[code] ??= <City>[]).add(city);
    }
  }
  return Map<String, List<City>>.unmodifiable(
    grouped.map(
      (key, value) =>
          MapEntry<String, List<City>>(key, List<City>.unmodifiable(value)),
    ),
  );
}
