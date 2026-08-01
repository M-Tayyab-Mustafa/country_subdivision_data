import 'dart:collection';

import '../utilities/json_parsing.dart';

/// A country in the bundled snapshot.
final class Country {
  /// Creates an immutable country value.
  Country({
    required this.id,
    required this.name,
    required this.iso2,
    required this.iso3,
    required List<String> timezones,
    this.nativeName,
    this.phoneCode,
    this.capital,
    this.currencyCode,
    this.currencyName,
    this.currencySymbol,
    this.region,
    this.subregion,
    this.latitude,
    this.longitude,
  }) : timezones = UnmodifiableListView<String>(List<String>.of(timezones));

  /// Creates a country from the normalized snapshot schema.
  factory Country.fromJson(Map<String, Object?> json) {
    final rawTimezones = json['timezones'];
    return Country(
      id: requiredInt(json['id'], 'id'),
      name: requiredString(json['name'], 'name'),
      iso2: requiredString(json['iso2'], 'iso2').toUpperCase(),
      iso3: requiredString(json['iso3'], 'iso3').toUpperCase(),
      nativeName: optionalString(json['nativeName']),
      phoneCode: optionalString(json['phoneCode']),
      capital: optionalString(json['capital']),
      currencyCode: optionalString(json['currencyCode']),
      currencyName: optionalString(json['currencyName']),
      currencySymbol: optionalString(json['currencySymbol']),
      region: optionalString(json['region']),
      subregion: optionalString(json['subregion']),
      latitude: optionalDouble(json['latitude']),
      longitude: optionalDouble(json['longitude']),
      timezones: rawTimezones is List<Object?>
          ? rawTimezones.whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }

  /// Stable upstream identifier.
  final int id;

  /// Display name.
  final String name;

  /// ISO 3166-1 alpha-2 code.
  final String iso2;

  /// ISO 3166-1 alpha-3 code.
  final String iso3;

  /// Native display name, when supplied upstream.
  final String? nativeName;

  /// International calling code.
  final String? phoneCode;

  /// Capital city name.
  final String? capital;

  /// Currency code.
  final String? currencyCode;

  /// Currency name.
  final String? currencyName;

  /// Currency symbol.
  final String? currencySymbol;

  /// Geographic region.
  final String? region;

  /// Geographic subregion.
  final String? subregion;

  /// Approximate latitude.
  final double? latitude;

  /// Approximate longitude.
  final double? longitude;

  /// IANA timezone identifiers associated with the country.
  final List<String> timezones;

  /// Converts this value to normalized snapshot JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'iso2': iso2,
    'iso3': iso3,
    'nativeName': nativeName,
    'phoneCode': phoneCode,
    'capital': capital,
    'currencyCode': currencyCode,
    'currencyName': currencyName,
    'currencySymbol': currencySymbol,
    'region': region,
    'subregion': subregion,
    'latitude': latitude,
    'longitude': longitude,
    'timezones': timezones,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          id == other.id &&
          name == other.name &&
          iso2 == other.iso2 &&
          iso3 == other.iso3 &&
          _listEquals(timezones, other.timezones) &&
          nativeName == other.nativeName &&
          phoneCode == other.phoneCode &&
          capital == other.capital &&
          currencyCode == other.currencyCode &&
          currencyName == other.currencyName &&
          currencySymbol == other.currencySymbol &&
          region == other.region &&
          subregion == other.subregion &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iso2,
    iso3,
    Object.hashAll(timezones),
    nativeName,
    phoneCode,
    capital,
    currencyCode,
    currencyName,
    currencySymbol,
    region,
    subregion,
    latitude,
    longitude,
  );

  @override
  String toString() => 'Country($iso2, $name)';
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
