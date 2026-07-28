import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'snapshot_validator.dart';
import 'tool_utils.dart';

const generatorVersion = '1.0.0';
const upstreamRepository = 'dr5hn/countries-states-cities-database';

final class SnapshotGenerationResult {
  const SnapshotGenerationResult({
    required this.upstreamCommit,
    required this.countryCount,
    required this.subdivisionCount,
    required this.cityCount,
    required this.snapshotSha256,
    required this.compressedBytes,
    required this.uncompressedBytes,
  });

  final String upstreamCommit;
  final int countryCount;
  final int subdivisionCount;
  final int cityCount;
  final String snapshotSha256;
  final int compressedBytes;
  final int uncompressedBytes;
}

SnapshotGenerationResult generateSnapshot({
  required Directory upstream,
  required Directory output,
  String? expectedCommit,
}) {
  final source = File(
    '${upstream.path}/json/countries+states+cities.json',
  );
  final license = File('${upstream.path}/LICENSE');
  if (!source.existsSync() || !license.existsSync()) {
    throw StateError(
      'Upstream checkout must contain json/countries+states+cities.json '
      'and LICENSE.',
    );
  }
  final licenseText = license.readAsStringSync();
  if (!licenseText.contains('Open Database License') &&
      !licenseText.contains('ODbL')) {
    throw StateError('The upstream checkout does not declare ODbL licensing.');
  }

  final commit = runGit(
    <String>['rev-parse', 'HEAD'],
    workingDirectory: upstream.path,
  );
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(commit)) {
    throw StateError('Could not resolve a full upstream commit SHA.');
  }
  if (expectedCommit != null && expectedCommit != commit) {
    throw StateError('Resolved commit $commit does not match $expectedCommit.');
  }
  final commitTime = DateTime.parse(
    runGit(
      <String>['show', '-s', '--format=%cI', commit],
      workingDirectory: upstream.path,
    ),
  ).toUtc();

  final rawCountries = readJsonList(source);
  final countries = <Map<String, Object?>>[];
  final dataByCountry = <String, Map<String, Object?>>{};
  final globalCountryIds = <int>{};
  final globalSubdivisionIds = <int>{};
  final globalCityIds = <int>{};

  for (final rawValue in rawCountries) {
    final raw = objectMap(rawValue, 'country');
    final id = integer(raw['id'], 'country.id');
    final iso2 = text(raw['iso2'], 'country.iso2').toUpperCase();
    final iso3 = text(raw['iso3'], 'country.iso3').toUpperCase();
    if (!globalCountryIds.add(id)) {
      throw FormatException('Duplicate country id $id.');
    }
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(iso2) ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(iso3)) {
      throw FormatException('Invalid ISO code for country id $id.');
    }

    final timezoneValues = <String>[];
    final rawTimezones = raw['timezones'];
    if (rawTimezones is List<Object?>) {
      for (final timezoneValue in rawTimezones) {
        final timezone = objectMap(timezoneValue, '$iso2 timezone');
        final zoneName = nullableText(timezone['zoneName']);
        if (zoneName != null) {
          timezoneValues.add(zoneName);
        }
      }
    }
    timezoneValues.sort();
    countries.add(<String, Object?>{
      'id': id,
      'name': text(raw['name'], '$iso2 country.name'),
      'iso2': iso2,
      'iso3': iso3,
      'nativeName': nullableText(raw['native']),
      'phoneCode': nullableText(raw['phonecode']),
      'capital': nullableText(raw['capital']),
      'currencyCode': nullableText(raw['currency']),
      'currencyName': nullableText(raw['currency_name']),
      'currencySymbol': nullableText(raw['currency_symbol']),
      'region': nullableText(raw['region']),
      'subregion': nullableText(raw['subregion']),
      'latitude': nullableNumber(raw['latitude']),
      'longitude': nullableNumber(raw['longitude']),
      'timezones': timezoneValues,
    });

    final subdivisions = <Map<String, Object?>>[];
    final cities = <Map<String, Object?>>[];
    final rawSubdivisions = raw['states'];
    if (rawSubdivisions is! List<Object?>) {
      throw FormatException('$iso2 states must be an array.');
    }
    for (final rawSubdivisionValue in rawSubdivisions) {
      final rawSubdivision = objectMap(
        rawSubdivisionValue,
        '$iso2 subdivision',
      );
      final subdivisionId = integer(
        rawSubdivision['id'],
        '$iso2 subdivision.id',
      );
      if (!globalSubdivisionIds.add(subdivisionId)) {
        throw FormatException('Duplicate subdivision id $subdivisionId.');
      }
      final subdivisionCode = nullableText(rawSubdivision['iso2']);
      subdivisions.add(<String, Object?>{
        'id': subdivisionId,
        'countryId': id,
        'countryCode': iso2,
        'name': text(
          rawSubdivision['name'],
          '$iso2 subdivision.name',
        ),
        'code': subdivisionCode,
        'type': nullableText(rawSubdivision['type']),
        'latitude': nullableNumber(rawSubdivision['latitude']),
        'longitude': nullableNumber(rawSubdivision['longitude']),
      });
      final rawCities = rawSubdivision['cities'];
      if (rawCities is! List<Object?>) {
        throw FormatException('$iso2 subdivision cities must be an array.');
      }
      for (final rawCityValue in rawCities) {
        final rawCity = objectMap(rawCityValue, '$iso2 city');
        final cityId = integer(rawCity['id'], '$iso2 city.id');
        if (!globalCityIds.add(cityId)) {
          throw FormatException('Duplicate city id $cityId.');
        }
        cities.add(<String, Object?>{
          'id': cityId,
          'countryId': id,
          'subdivisionId': subdivisionId,
          'countryCode': iso2,
          'subdivisionCode': subdivisionCode,
          'name': text(rawCity['name'], '$iso2 city.name'),
          'latitude': nullableNumber(rawCity['latitude']),
          'longitude': nullableNumber(rawCity['longitude']),
          'timezone': nullableText(rawCity['timezone']),
        });
      }
    }
    subdivisions.sort(_compareSubdivisions);
    cities.sort(_compareCities);
    dataByCountry[iso2] = <String, Object?>{
      'countryCode': iso2,
      'subdivisions': subdivisions,
      'cities': cities,
    };
  }
  countries.sort(
    (left, right) => (left['iso2']! as String).compareTo(
      right['iso2']! as String,
    ),
  );

  final parent = output.parent;
  parent.createSync(recursive: true);
  final temporary = Directory(
    '${output.path}.tmp-${DateTime.now().microsecondsSinceEpoch}',
  )..createSync(recursive: true);
  Directory('${temporary.path}/countries').createSync();
  final deterministicFiles = <String, List<int>>{};
  final countriesBytes = utf8.encode(prettyJson(countries));
  File('${temporary.path}/countries.json').writeAsBytesSync(countriesBytes);
  deterministicFiles['countries.json'] = countriesBytes;

  var compressedBytes = 0;
  var uncompressedBytes = 0;
  final fileIndex = <Map<String, Object?>>[];
  for (final country in countries) {
    final code = country['iso2']! as String;
    final uncompressed = utf8.encode(prettyJson(dataByCountry[code]));
    final compressed = gzip.encode(uncompressed);
    final relativePath = 'countries/$code.json.gz';
    File('${temporary.path}/$relativePath').writeAsBytesSync(compressed);
    deterministicFiles[relativePath] = compressed;
    compressedBytes += compressed.length;
    uncompressedBytes += uncompressed.length;
    final data = dataByCountry[code]!;
    fileIndex.add(<String, Object?>{
      'countryCode': code,
      'path': relativePath,
      'sha256': sha256.convert(compressed).toString(),
      'subdivisions': (data['subdivisions']! as List<Object?>).length,
      'cities': (data['cities']! as List<Object?>).length,
      'compressedBytes': compressed.length,
      'uncompressedBytes': uncompressed.length,
    });
  }

  final snapshotDigest = _snapshotDigest(deterministicFiles);
  final manifest = <String, Object?>{
    'schemaVersion': 1,
    'generatedAt': commitTime.toIso8601String(),
    'upstreamRepository': upstreamRepository,
    'upstreamCommit': commit,
    'upstreamRelease': null,
    'countries': countries.length,
    'subdivisions': globalSubdivisionIds.length,
    'cities': globalCityIds.length,
    'sha256': snapshotDigest,
    'generatorVersion': generatorVersion,
    'license': 'ODbL-1.0',
    'compressedBytes': compressedBytes,
    'uncompressedBytes': uncompressedBytes,
    'checksumFiles': deterministicFiles.keys.toList(growable: false),
    'files': fileIndex,
  };
  File('${temporary.path}/manifest.json').writeAsStringSync(
    prettyJson(manifest),
  );
  File('${temporary.path}/SIZE_REPORT.md').writeAsStringSync(
    '# Generated snapshot size\n\n'
    '- Countries: ${countries.length}\n'
    '- Subdivisions: ${globalSubdivisionIds.length}\n'
    '- Cities: ${globalCityIds.length}\n'
    '- Compressed country data: $compressedBytes bytes\n'
    '- Uncompressed country data: $uncompressedBytes bytes\n'
    '- Snapshot SHA-256: `$snapshotDigest`\n',
  );

  validateSnapshot(temporary, minimumCountries: 249);
  final backup = Directory('${output.path}.backup');
  if (backup.existsSync()) {
    backup.deleteSync(recursive: true);
  }
  if (output.existsSync()) {
    output.renameSync(backup.path);
  }
  try {
    temporary.renameSync(output.path);
    if (backup.existsSync()) {
      backup.deleteSync(recursive: true);
    }
  } on Object {
    if (output.existsSync()) {
      output.deleteSync(recursive: true);
    }
    if (backup.existsSync()) {
      backup.renameSync(output.path);
    }
    rethrow;
  }
  return SnapshotGenerationResult(
    upstreamCommit: commit,
    countryCount: countries.length,
    subdivisionCount: globalSubdivisionIds.length,
    cityCount: globalCityIds.length,
    snapshotSha256: snapshotDigest,
    compressedBytes: compressedBytes,
    uncompressedBytes: uncompressedBytes,
  );
}

int _compareSubdivisions(
  Map<String, Object?> left,
  Map<String, Object?> right,
) {
  final name = normalizeForSort(
    left['name']! as String,
  ).compareTo(normalizeForSort(right['name']! as String));
  if (name != 0) {
    return name;
  }
  final code = (left['code'] as String? ?? '').compareTo(
    right['code'] as String? ?? '',
  );
  return code != 0 ? code : (left['id']! as int).compareTo(right['id']! as int);
}

int _compareCities(Map<String, Object?> left, Map<String, Object?> right) {
  final subdivision = (left['subdivisionCode'] as String? ?? '').compareTo(
    right['subdivisionCode'] as String? ?? '',
  );
  if (subdivision != 0) {
    return subdivision;
  }
  final name = normalizeForSort(
    left['name']! as String,
  ).compareTo(normalizeForSort(right['name']! as String));
  return name != 0 ? name : (left['id']! as int).compareTo(right['id']! as int);
}

String _snapshotDigest(Map<String, List<int>> files) {
  final bytes = <int>[];
  for (final path in files.keys.toList()..sort()) {
    bytes
      ..addAll(utf8.encode(path))
      ..add(0)
      ..addAll(files[path]!)
      ..add(0);
  }
  return sha256.convert(bytes).toString();
}
