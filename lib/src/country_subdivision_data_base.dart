import 'models/city.dart';
import 'models/country.dart';
import 'models/country_subdivision_snapshot_metadata.dart';
import 'models/subdivision.dart';
import 'repository/asset_country_subdivision_repository.dart';
import 'repository/country_subdivision_repository.dart';

/// Main facade for bundled country, subdivision, and city data.
final class CountrySubdivisionData {
  /// Creates a facade, optionally with a custom repository.
  CountrySubdivisionData({CountrySubdivisionRepository? repository})
    : _repository = repository ?? AssetCountrySubdivisionRepository();

  /// Shared facade backed by package assets.
  static final CountrySubdivisionData instance = CountrySubdivisionData();

  final CountrySubdivisionRepository _repository;

  /// Whether initialization completed successfully.
  bool get isInitialized => _repository.isInitialized;

  /// Metadata for the initialized snapshot.
  CountrySubdivisionSnapshotMetadata get snapshotMetadata =>
      _repository.snapshotMetadata;

  /// Loads the small country manifest. Concurrent calls share one operation.
  Future<void> initialize() => _repository.initialize();

  /// Returns all countries ordered by ISO2.
  Future<List<Country>> getCountries() => _repository.getCountries();

  /// Looks up either a two-letter or three-letter ISO country code.
  Future<Country?> getCountryByCode(String code) =>
      _repository.getCountryByCode(code);

  /// Looks up an ISO2 code case-insensitively.
  Future<Country?> getCountryByIso2(String iso2) =>
      _repository.getCountryByIso2(iso2);

  /// Looks up an ISO3 code case-insensitively.
  Future<Country?> getCountryByIso3(String iso3) =>
      _repository.getCountryByIso3(iso3);

  /// Lazily returns subdivisions for one ISO2 country code.
  Future<List<Subdivision>> getSubdivisions({required String countryCode}) =>
      _repository.getSubdivisions(countryCode: countryCode);

  /// Looks up a country-scoped subdivision code case-insensitively.
  Future<Subdivision?> getSubdivisionByCode({
    required String countryCode,
    required String subdivisionCode,
  }) => _repository.getSubdivisionByCode(
    countryCode: countryCode,
    subdivisionCode: subdivisionCode,
  );

  /// Looks up a subdivision by stable identifier.
  Future<Subdivision?> getSubdivisionById(int id) =>
      _repository.getSubdivisionById(id);

  /// Lazily returns cities, optionally within one subdivision.
  Future<List<City>> getCities({
    required String countryCode,
    String? subdivisionCode,
  }) => _repository.getCities(
    countryCode: countryCode,
    subdivisionCode: subdivisionCode,
  );

  /// Looks up a city by stable identifier.
  Future<City?> getCityById(int id) => _repository.getCityById(id);

  /// Searches country names and ISO codes.
  Future<List<Country>> searchCountries({
    required String query,
    int limit = 20,
  }) => _repository.searchCountries(query: query, limit: limit);

  /// Searches subdivision names and codes.
  Future<List<Subdivision>> searchSubdivisions({
    required String query,
    String? countryCode,
    int limit = 20,
  }) => _repository.searchSubdivisions(
    query: query,
    countryCode: countryCode,
    limit: limit,
  );

  /// Searches city names with optional country and subdivision scopes.
  Future<List<City>> searchCities({
    required String query,
    String? countryCode,
    String? subdivisionCode,
    int limit = 20,
  }) => _repository.searchCities(
    query: query,
    countryCode: countryCode,
    subdivisionCode: subdivisionCode,
    limit: limit,
  );

  /// Loads one country into the bounded cache.
  Future<void> preloadCountry(String countryCode) =>
      _repository.preloadCountry(countryCode);

  /// Clears lazily loaded country data while retaining the small manifest.
  Future<void> clearCache() => _repository.clearCache();
}
