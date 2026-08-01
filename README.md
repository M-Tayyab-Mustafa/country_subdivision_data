# country_subdivision_data

Offline, versioned country, first-level subdivision, and city data for Flutter.
It also includes a customizable country-aware phone form field and searchable
country-picker dialog.
The package controls an optimized snapshot of
[`dr5hn/countries-states-cities-database`](https://github.com/dr5hn/countries-states-cities-database)
instead of tying applications to a picker package's data or release schedule.
After installation, geographic lookups do not require a network connection.

## Installation

```yaml
dependencies:
  country_subdivision_data: ^0.0.1
```

```dart
import 'package:country_subdivision_data/country_subdivision_data.dart';
```

## Usage

Initialization reads only the small country manifest. Country payloads are
decompressed and parsed on demand.

```dart
final data = CountrySubdivisionData.instance;
await data.initialize();

final countries = await data.getCountries();
final nigeria = await data.getCountryByCode('NG');
final subdivisions = await data.getSubdivisions(countryCode: 'NG');
final rivers = await data.getSubdivisionByCode(
  countryCode: 'NG',
  subdivisionCode: 'RI',
);
final cities = await data.getCities(
  countryCode: 'NG',
  subdivisionCode: 'RI',
);
final results = await data.searchCities(
  query: 'Port Harcourt',
  countryCode: 'NG',
  limit: 20,
);
```

ISO2, ISO3, and subdivision-code lookups trim whitespace and ignore case.
Search ignores case, repeated whitespace, and common Latin diacritics. It ranks
exact, prefix, then substring matches deterministically. Empty queries return an
empty list; non-positive limits throw `ArgumentError`.

Unknown country and subdivision codes produce `null` for single lookups and an
empty list for collections. Do not add fake `Other` or `Not listed` records.
Applications should expose a separate “State or city not listed” action and
store user-entered text separately.

## Phone field and country picker

`CountryPhoneField` loads calling codes from the same offline snapshot:

```dart
CountryPhoneField(
  initialCountryCode: 'NG',
  decoration: const InputDecoration(
    labelText: 'Phone number',
    border: OutlineInputBorder(),
  ),
  validator: (value) {
    if (value == null || value.nationalDigits.length < 7) {
      return 'Enter a phone number';
    }
    return null;
  },
  onChanged: (value) {
    print(value.country.iso2);        // NG
    print(value.dialingCode);         // +234
    print(value.internationalNumber); // +234...
  },
);
```

The default picker searches country names, native names, ISO2/ISO3 codes, and
calling codes. Its search field and rows can be replaced independently:

```dart
CountryPhoneField(
  favoriteCountryCodes: const ['NG', 'US', 'GB'],
  countryFilter: (country) => country.phoneCode != null,
  pickerConfiguration: const CountryPickerDialogConfiguration(
    title: 'Choose calling code',
    searchHintText: 'Country or calling code',
    dialogHeight: 520,
    showIsoCode: true,
    selectedColor: Color(0xFFE8EAF6),
  ),
  pickerSearchFieldBuilder: (context, controller, onChanged) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Custom search',
        prefixIcon: Icon(Icons.travel_explore),
      ),
    );
  },
  pickerItemBuilder: (context, country, selected, select) {
    return ListTile(
      selected: selected,
      title: Text(country.name),
      trailing: Text(normalizedDialingCode(country)),
      onTap: select,
    );
  },
);
```

Additional hooks replace the selector, complete phone text field, picker
presenter/route, dialog shell, title, flags, empty state, loading state, and
error state. `CountryPickerDialog` and `showCountryPickerDialog` can also be
used independently.

The package only composes the selected calling code with user-entered digits.
It does not remove national trunk prefixes or claim country-specific validity;
use the structured `validator` callback for application requirements.

## Loading and cache behavior

Each country has one gzip-compressed JSON asset. Initialization does not parse
all cities. Concurrent requests for one country share the same load. The
default repository retains up to eight recently used country datasets:

```dart
await data.preloadCountry('NG');
await data.clearCache(); // The small manifest remains initialized.
```

Global subdivision or city searches intentionally load each country. Prefer a
country filter for lower latency and memory use.

## Snapshot metadata and size

```dart
final metadata = data.snapshotMetadata;
print(metadata.upstreamCommit);
print(metadata.snapshotSha256);
```

The bundled snapshot contains 250 countries, 5,308 subdivisions, and 152,970
cities from upstream commit
`81d127720a3da919c5d3da95a662316626a1ce49`. Country payloads occupy 3,591,341
compressed bytes and 41,577,208 uncompressed bytes. Flutter's final application
packaging and platform compression determine installed size, so measure your
own release build.

The checksum covers `countries.json` and every `countries/XX.json.gz` file,
including each relative path and a zero-byte separator. It excludes
`manifest.json`, reports, and timestamps. The commit timestamp is used for
`generatedAt`, making regeneration from one commit deterministic.

## Updating and validation

```bash
dart run tool/generate_snapshot.dart \
  --upstream-path ../countries-states-cities-database
dart run tool/validate_snapshot.dart
dart run tool/upstream_data_manager.dart verify
```

Malformed optional numeric fields become `null`; required identifiers, names,
and relationships reject generation. Missing codes are never fabricated.
Generation writes to a temporary directory, validates it, and only then replaces
the committed snapshot.

Flutter and upstream data are checked together monthly. Any newer official
stable Flutter version updates the exact development pin, including minor and
patch releases. A verified upstream commit releases only when normalized
publishable data changes. A combined run performs one package-version bump.
No-change runs create no commit, tag, release, or publication. After the one-time
manual publication of `0.0.1` and OIDC configuration, eligible monthly runs are
fully automatic. They update only `automation/monthly-maintenance`, open a pull
request to protected `main`, refresh that branch whenever `main` changes, and
enable squash auto-merge. The release GitHub App creates the immutable
`v{{version}}` tag only after GitHub merges that pull request and the tagged
commit is verified on `main`. Only that tag can trigger pub.dev OIDC
publication.

The custom version sequence rolls `0.0.9` to `0.1.0` and `0.9.9` to `1.0.0`;
minor and patch components never exceed nine.

Run the complete local checks:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run tool/validate_snapshot.dart
dart run tool/flutter_sdk_manager.dart verify
dart run tool/version_manager.dart verify
dart pub publish --dry-run
```

## Limitations

This community-maintained snapshot can lag political or administrative changes
and should not be the sole source for legal, postal, emergency, or compliance
decisions. It provides first-level subdivisions as represented upstream, not a
uniform global ontology or locale-aware fuzzy search.

## Licensing and attribution

Original Dart source is BSD-3-Clause licensed. Generated geographic data is
derived from Countries States Cities Database and remains subject to ODbL 1.0:

> Data by Countries States Cities Database<br>
> https://github.com/dr5hn/countries-states-cities-database | ODbL v1.0

See [NOTICE](NOTICE) for the exact source commit and attribution. Redistribution
and produced-work obligations under ODbL should receive human legal review.
Contributions are described in [CONTRIBUTING.md](CONTRIBUTING.md).
