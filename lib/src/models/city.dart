import '../utilities/json_parsing.dart';

/// A city or equivalent locality in the bundled snapshot.
final class City {
  /// Creates an immutable city value.
  const City({
    required this.id,
    required this.countryId,
    required this.countryCode,
    required this.name,
    this.subdivisionId,
    this.subdivisionCode,
    this.latitude,
    this.longitude,
    this.timezone,
  });

  /// Creates a city from normalized snapshot JSON.
  factory City.fromJson(Map<String, Object?> json) => City(
    id: requiredInt(json['id'], 'id'),
    countryId: requiredInt(json['countryId'], 'countryId'),
    subdivisionId: optionalInt(json['subdivisionId']),
    countryCode: requiredString(
      json['countryCode'],
      'countryCode',
    ).toUpperCase(),
    subdivisionCode: optionalString(json['subdivisionCode']),
    name: requiredString(json['name'], 'name'),
    latitude: optionalDouble(json['latitude']),
    longitude: optionalDouble(json['longitude']),
    timezone: optionalString(json['timezone']),
  );

  /// Stable upstream identifier.
  final int id;

  /// Identifier of the owning country.
  final int countryId;

  /// Identifier of the owning subdivision, when known.
  final int? subdivisionId;

  /// ISO2 code of the owning country.
  final String countryCode;

  /// Country-scoped subdivision code, when known.
  final String? subdivisionCode;

  /// Display name.
  final String name;

  /// Approximate latitude.
  final double? latitude;

  /// Approximate longitude.
  final double? longitude;

  /// IANA timezone identifier.
  final String? timezone;

  /// Converts this value to normalized snapshot JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'countryId': countryId,
    'subdivisionId': subdivisionId,
    'countryCode': countryCode,
    'subdivisionCode': subdivisionCode,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          id == other.id &&
          countryId == other.countryId &&
          subdivisionId == other.subdivisionId &&
          countryCode == other.countryCode &&
          subdivisionCode == other.subdivisionCode &&
          name == other.name &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timezone == other.timezone;

  @override
  int get hashCode => Object.hash(
    id,
    countryId,
    subdivisionId,
    countryCode,
    subdivisionCode,
    name,
    latitude,
    longitude,
    timezone,
  );

  @override
  String toString() => 'City($countryCode, $name)';
}
