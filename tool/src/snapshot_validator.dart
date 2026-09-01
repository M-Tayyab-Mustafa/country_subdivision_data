import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'tool_utils.dart';

final class SnapshotValidationResult {
  const SnapshotValidationResult({
    required this.countries,
    required this.subdivisions,
    required this.cities,
    required this.sha256,
  });

  final int countries;
  final int subdivisions;
  final int cities;
  final String sha256;
}

SnapshotValidationResult validateSnapshot(
  Directory snapshot, {
  int minimumCountries = 249,
}) {
  final manifestFile = File('${snapshot.path}/manifest.json');
  final countriesFile = File('${snapshot.path}/countries.json');
  if (!manifestFile.existsSync() || !countriesFile.existsSync()) {
    throw StateError('Snapshot manifest or countries file is missing.');
  }
  final manifest = readJsonMap(manifestFile);
  if (integer(manifest['schemaVersion'], 'schemaVersion') != 1) {
    throw FormatException('Unsupported snapshot schema.');
  }
  final commit = text(manifest['upstreamCommit'], 'upstreamCommit');
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(commit)) {
    throw FormatException('Manifest upstream commit is not a full SHA.');
  }
  final countriesJson = readJsonList(countriesFile);
  if (countriesJson.length < minimumCountries) {
    throw FormatException(
      'Expected at least $minimumCountries countries, found '
      '${countriesJson.length}.',
    );
  }
  final countryIds = <int>{};
  final iso2Codes = <String>{};
  final iso3Codes = <String>{};
  for (final value in countriesJson) {
    final country = objectMap(value, 'country');
    final id = integer(country['id'], 'country.id');
    final iso2 = text(country['iso2'], 'country.iso2');
    final iso3 = text(country['iso3'], 'country.iso3');
    if (!countryIds.add(id) ||
        !iso2Codes.add(iso2) ||
        !iso3Codes.add(iso3) ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(iso2) ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(iso3) ||
        text(country['name'], '$iso2 name').isEmpty) {
      throw FormatException('Invalid or duplicate country $iso2.');
    }
  }

  final rawFiles = manifest['files'];
  final rawChecksumFiles = manifest['checksumFiles'];
  if (rawFiles is! List<Object?> || rawChecksumFiles is! List<Object?>) {
    throw FormatException('Manifest file indexes are missing.');
  }
  if (rawFiles.length != countriesJson.length) {
    throw FormatException('Country file index count is incorrect.');
  }
  final expectedPaths = <String>{};
  final subdivisionIds = <int>{};
  final cityIds = <int>{};
  final subdivisionCountry = <int, int>{};
  final subdivisionsByCountryAndCode = <String>{};
  Map<String, Object?>? nigeriaData;

  for (final value in rawFiles) {
    final index = objectMap(value, 'file index');
    final code = text(index['countryCode'], 'file.countryCode');
    final relativePath = text(index['path'], 'file.path');
    if (relativePath != 'countries/$code.json.gz' ||
        !iso2Codes.contains(code) ||
        !expectedPaths.add(relativePath)) {
      throw FormatException('Invalid or duplicate file entry $relativePath.');
    }
    final file = File('${snapshot.path}/$relativePath');
    if (!file.existsSync()) {
      throw StateError('Missing generated file $relativePath.');
    }
    final compressed = file.readAsBytesSync();
    if (sha256.convert(compressed).toString() != index['sha256']) {
      throw FormatException('Checksum mismatch for $relativePath.');
    }
    final decoded = jsonDecode(utf8.decode(gzip.decode(compressed)));
    final data = objectMap(decoded, relativePath);
    if (data['countryCode'] != code) {
      throw FormatException('Country code mismatch in $relativePath.');
    }
    final subdivisions = data['subdivisions'];
    final cities = data['cities'];
    if (subdivisions is! List<Object?> || cities is! List<Object?>) {
      throw FormatException('Invalid arrays in $relativePath.');
    }
    if (subdivisions.length != index['subdivisions'] ||
        cities.length != index['cities']) {
      throw FormatException('Count mismatch in $relativePath.');
    }
    final country = objectMap(
      countriesJson.firstWhere(
        (item) => objectMap(item, 'country')['iso2'] == code,
      ),
      code,
    );
    final countryId = integer(country['id'], '$code country.id');
    for (final subdivisionValue in subdivisions) {
      final subdivision = objectMap(subdivisionValue, '$code subdivision');
      final id = integer(subdivision['id'], '$code subdivision.id');
      final subdivisionCode = nullableText(subdivision['code']);
      if (!subdivisionIds.add(id) ||
          integer(subdivision['countryId'], '$code countryId') != countryId ||
          subdivision['countryCode'] != code ||
          nullableText(subdivision['name']) == null) {
        throw FormatException('Invalid subdivision $id in $code.');
      }
      subdivisionCountry[id] = countryId;
      if (subdivisionCode != null &&
          !subdivisionsByCountryAndCode.add('$code\u0000$subdivisionCode')) {
        throw FormatException(
          'Duplicate subdivision code $code-$subdivisionCode.',
        );
      }
    }
    for (final cityValue in cities) {
      final city = objectMap(cityValue, '$code city');
      final id = integer(city['id'], '$code city.id');
      final subdivisionId = integer(
        city['subdivisionId'],
        '$code city.subdivisionId',
      );
      if (!cityIds.add(id) ||
          integer(city['countryId'], '$code city.countryId') != countryId ||
          city['countryCode'] != code ||
          nullableText(city['name']) == null ||
          subdivisionCountry[subdivisionId] != countryId) {
        throw FormatException('Invalid city $id in $code.');
      }
    }
    if (code == 'NG') {
      nigeriaData = data;
    }
  }

  final actualGenerated = Directory('${snapshot.path}/countries')
      .listSync()
      .whereType<File>()
      .map((file) => 'countries/${file.uri.pathSegments.last}')
      .toSet();
  if (actualGenerated.length != expectedPaths.length ||
      !actualGenerated.containsAll(expectedPaths)) {
    throw FormatException('Unexpected generated country files exist.');
  }

  final deterministicFiles = <String, List<int>>{
    'countries.json': countriesFile.readAsBytesSync(),
    for (final path in expectedPaths)
      path: File('${snapshot.path}/$path').readAsBytesSync(),
  };
  final digestBytes = <int>[];
  for (final path in deterministicFiles.keys.toList()..sort()) {
    digestBytes
      ..addAll(utf8.encode(path))
      ..add(0)
      ..addAll(deterministicFiles[path]!)
      ..add(0);
  }
  final digest = sha256.convert(digestBytes).toString();
  if (digest != manifest['sha256']) {
    throw FormatException('Snapshot SHA-256 mismatch.');
  }
  if (countriesJson.length != manifest['countries'] ||
      subdivisionIds.length != manifest['subdivisions'] ||
      cityIds.length != manifest['cities']) {
    throw FormatException('Global manifest counts do not match.');
  }
  _validateNigeria(nigeriaData);
  return SnapshotValidationResult(
    countries: countriesJson.length,
    subdivisions: subdivisionIds.length,
    cities: cityIds.length,
    sha256: digest,
  );
}

void _validateNigeria(Map<String, Object?>? data) {
  if (data == null) {
    throw FormatException('Nigeria is missing.');
  }
  final subdivisions = data['subdivisions']! as List<Object?>;
  final cities = data['cities']! as List<Object?>;
  if (subdivisions.length != 37) {
    throw FormatException(
      'Nigeria must contain exactly 37 first-level subdivisions.',
    );
  }
  final rivers = subdivisions
      .map((value) => objectMap(value, 'Nigeria subdivision'))
      .where((value) => value['code'] == 'RI')
      .toList();
  if (rivers.length != 1 ||
      rivers.single['name'].toString().toLowerCase() != 'rivers') {
    throw FormatException('Nigeria Rivers subdivision (RI) is missing.');
  }
  final riversId = rivers.single['id'];
  final portHarcourt =
      cities.map((value) => objectMap(value, 'Nigeria city')).where(
            (value) =>
                value['name'].toString().toLowerCase() == 'port harcourt' &&
                value['subdivisionId'] == riversId &&
                value['subdivisionCode'] == 'RI',
          );
  if (portHarcourt.isEmpty) {
    throw FormatException('Port Harcourt is not assigned to Rivers.');
  }
}
