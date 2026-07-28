import '../utilities/json_parsing.dart';

/// Provenance, integrity, and record counts for the bundled snapshot.
final class CountrySubdivisionSnapshotMetadata {
  /// Creates immutable snapshot metadata.
  const CountrySubdivisionSnapshotMetadata({
    required this.schemaVersion,
    required this.generatedAt,
    required this.upstreamRepository,
    required this.upstreamCommit,
    required this.countryCount,
    required this.subdivisionCount,
    required this.cityCount,
    required this.snapshotSha256,
    required this.generatorVersion,
    required this.dataLicense,
    this.upstreamRelease,
    this.compressedBytes,
    this.uncompressedBytes,
  });

  /// Creates metadata from the snapshot manifest.
  factory CountrySubdivisionSnapshotMetadata.fromJson(
    Map<String, Object?> json,
  ) =>
      CountrySubdivisionSnapshotMetadata(
        schemaVersion: requiredInt(json['schemaVersion'], 'schemaVersion'),
        generatedAt: DateTime.parse(
          requiredString(json['generatedAt'], 'generatedAt'),
        ).toUtc(),
        upstreamRepository: requiredString(
          json['upstreamRepository'],
          'upstreamRepository',
        ),
        upstreamCommit:
            requiredString(json['upstreamCommit'], 'upstreamCommit'),
        upstreamRelease: optionalString(json['upstreamRelease']),
        countryCount: requiredInt(json['countries'], 'countries'),
        subdivisionCount: requiredInt(json['subdivisions'], 'subdivisions'),
        cityCount: requiredInt(json['cities'], 'cities'),
        snapshotSha256: requiredString(json['sha256'], 'sha256'),
        generatorVersion: requiredString(
          json['generatorVersion'],
          'generatorVersion',
        ),
        dataLicense: requiredString(json['license'], 'license'),
        compressedBytes: optionalInt(json['compressedBytes']),
        uncompressedBytes: optionalInt(json['uncompressedBytes']),
      );

  /// Snapshot format version.
  final int schemaVersion;

  /// Stable source-commit time used for generation metadata.
  final DateTime generatedAt;

  /// Upstream repository slug.
  final String upstreamRepository;

  /// Exact upstream Git commit.
  final String upstreamCommit;

  /// Upstream release name, if generation used one.
  final String? upstreamRelease;

  /// Number of countries.
  final int countryCount;

  /// Number of first-level subdivisions.
  final int subdivisionCount;

  /// Number of cities.
  final int cityCount;

  /// SHA-256 over the deterministic countries manifest and country files.
  final String snapshotSha256;

  /// Snapshot generator version.
  final String generatorVersion;

  /// SPDX identifier for the upstream data license.
  final String dataLicense;

  /// Total compressed country-data bytes.
  final int? compressedBytes;

  /// Total uncompressed country-data bytes.
  final int? uncompressedBytes;

  /// Converts this value to normalized manifest JSON.
  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'upstreamRepository': upstreamRepository,
        'upstreamCommit': upstreamCommit,
        'upstreamRelease': upstreamRelease,
        'countries': countryCount,
        'subdivisions': subdivisionCount,
        'cities': cityCount,
        'sha256': snapshotSha256,
        'generatorVersion': generatorVersion,
        'license': dataLicense,
        'compressedBytes': compressedBytes,
        'uncompressedBytes': uncompressedBytes,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountrySubdivisionSnapshotMetadata &&
          schemaVersion == other.schemaVersion &&
          generatedAt == other.generatedAt &&
          upstreamRepository == other.upstreamRepository &&
          upstreamCommit == other.upstreamCommit &&
          upstreamRelease == other.upstreamRelease &&
          countryCount == other.countryCount &&
          subdivisionCount == other.subdivisionCount &&
          cityCount == other.cityCount &&
          snapshotSha256 == other.snapshotSha256 &&
          generatorVersion == other.generatorVersion &&
          dataLicense == other.dataLicense &&
          compressedBytes == other.compressedBytes &&
          uncompressedBytes == other.uncompressedBytes;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        generatedAt,
        upstreamRepository,
        upstreamCommit,
        upstreamRelease,
        countryCount,
        subdivisionCount,
        cityCount,
        snapshotSha256,
        generatorVersion,
        dataLicense,
        compressedBytes,
        uncompressedBytes,
      );

  @override
  String toString() => 'CountrySubdivisionSnapshotMetadata('
      '$countryCount countries, $subdivisionCount subdivisions, '
      '$cityCount cities, $upstreamCommit)';
}
