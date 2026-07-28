import '../models/city.dart';
import '../models/country.dart';
import '../models/country_subdivision_snapshot_metadata.dart';
import '../models/subdivision.dart';

/// Storage abstraction used by [CountrySubdivisionData].
abstract interface class CountrySubdivisionRepository {
  /// Whether [initialize] completed successfully.
  bool get isInitialized;

  /// Metadata for the initialized snapshot.
  CountrySubdivisionSnapshotMetadata get snapshotMetadata;

  /// Loads the country manifest. Calls are idempotent.
  Future<void> initialize();

  /// Returns all countries ordered by ISO2.
  Future<List<Country>> getCountries();

  /// Looks up a country by ISO2 or ISO3 code.
  Future<Country?> getCountryByCode(String code);

  /// Looks up a country by ISO2 code.
  Future<Country?> getCountryByIso2(String iso2);

  /// Looks up a country by ISO3 code.
  Future<Country?> getCountryByIso3(String iso3);

  /// Returns subdivisions for [countryCode].
  Future<List<Subdivision>> getSubdivisions({required String countryCode});

  /// Looks up a country-scoped subdivision code.
  Future<Subdivision?> getSubdivisionByCode({
    required String countryCode,
    required String subdivisionCode,
  });

  /// Looks up a subdivision by its stable identifier.
  Future<Subdivision?> getSubdivisionById(int id);

  /// Returns cities, optionally scoped to [subdivisionCode].
  Future<List<City>> getCities({
    required String countryCode,
    String? subdivisionCode,
  });

  /// Looks up a city by its stable identifier.
  Future<City?> getCityById(int id);

  /// Searches country names and ISO codes.
  Future<List<Country>> searchCountries({
    required String query,
    int limit = 20,
  });

  /// Searches subdivision names.
  Future<List<Subdivision>> searchSubdivisions({
    required String query,
    String? countryCode,
    int limit = 20,
  });

  /// Searches city names.
  Future<List<City>> searchCities({
    required String query,
    String? countryCode,
    String? subdivisionCode,
    int limit = 20,
  });

  /// Loads and caches one country dataset.
  Future<void> preloadCountry(String countryCode);

  /// Removes all lazily loaded country datasets from memory.
  Future<void> clearCache();
}
