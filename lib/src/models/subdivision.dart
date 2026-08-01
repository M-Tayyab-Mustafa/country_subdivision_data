import '../utilities/json_parsing.dart';

/// A first-level administrative subdivision such as a state or province.
final class Subdivision {
  /// Creates an immutable subdivision value.
  const Subdivision({
    required this.id,
    required this.countryId,
    required this.countryCode,
    required this.name,
    this.code,
    this.type,
    this.latitude,
    this.longitude,
  });

  /// Creates a subdivision from normalized snapshot JSON.
  factory Subdivision.fromJson(Map<String, Object?> json) => Subdivision(
    id: requiredInt(json['id'], 'id'),
    countryId: requiredInt(json['countryId'], 'countryId'),
    countryCode: requiredString(
      json['countryCode'],
      'countryCode',
    ).toUpperCase(),
    name: requiredString(json['name'], 'name'),
    code: optionalString(json['code']),
    type: optionalString(json['type']),
    latitude: optionalDouble(json['latitude']),
    longitude: optionalDouble(json['longitude']),
  );

  /// Stable upstream identifier.
  final int id;

  /// Identifier of the owning country.
  final int countryId;

  /// ISO2 code of the owning country.
  final String countryCode;

  /// Display name.
  final String name;

  /// Country-scoped subdivision code.
  final String? code;

  /// Upstream subdivision classification, when supplied.
  final String? type;

  /// Approximate latitude.
  final double? latitude;

  /// Approximate longitude.
  final double? longitude;

  /// Converts this value to normalized snapshot JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'countryId': countryId,
    'countryCode': countryCode,
    'name': name,
    'code': code,
    'type': type,
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subdivision &&
          id == other.id &&
          countryId == other.countryId &&
          countryCode == other.countryCode &&
          name == other.name &&
          code == other.code &&
          type == other.type &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(
    id,
    countryId,
    countryCode,
    name,
    code,
    type,
    latitude,
    longitude,
  );

  @override
  String toString() => 'Subdivision($countryCode-${code ?? id}, $name)';
}
