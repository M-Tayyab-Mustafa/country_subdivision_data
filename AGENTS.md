# Repository agent guide

This is the Flutter package `country_subdivision_data`. Its facade is
`CountrySubdivisionData`; public models are `Country`, `Subdivision`, `City`,
and `CountrySubdivisionSnapshotMetadata`. Repositories are
`CountrySubdivisionRepository` and `AssetCountrySubdivisionRepository`.
Optional Flutter UI is exposed through `CountryPhoneField`,
`CountryPickerDialog`, and `CountryPhoneNumber`; keep every visual component
customizable and backed by the offline country snapshot.
Public APIs must say “subdivision”; never reintroduce legacy package or
administrative-area model names.

Runtime code lives in `lib`; pure-Dart maintenance tools live in `tool`.
`assets/country_subdivision_data/countries.json`, `manifest.json`, and every
`countries/*.json.gz` file are generated and must not be manually edited.
The snapshot checksum covers the country list and compressed country payloads,
including paths, but excludes the manifest and reports.

Commands:

```bash
dart run tool/generate_snapshot.dart --upstream-path PATH
dart run tool/validate_snapshot.dart
dart run tool/upstream_data_manager.dart verify
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run tool/flutter_sdk_manager.dart verify
dart run tool/version_manager.dart verify
dart pub publish --dry-run
```

Generation must be deterministic, preserve ODbL attribution, validate all
foreign keys, and retain Nigeria's 37 first-level subdivisions, Rivers `RI`,
and Port Harcourt relationship. Do not fabricate missing values.

The initial package version is `0.0.1`. Version rollover is `0.0.9 → 0.1.0` and
`0.9.9 → 1.0.0`; never create `0.0.10` or `0.10.0`. No eligible maintenance
change means no bump. Combined Flutter/data maintenance receives exactly one
bump.

Only official stable Flutter versions may be pinned. Never use `latest` in CI,
downgrade automatically, mutate a developer's global Flutter installation,
or raise minimum SDK constraints just because the development pin changed.
Monthly automation checks Flutter and upstream together: Flutter requires a
newer stable semantic version; upstream requires meaningful verified
publishable differences.

After the one-time manual `0.0.1` publication, eligible monthly releases are
fully automated. Complete validation is mandatory before commit and again
before tag publication. The monthly workflow may push only
`automation/monthly-maintenance`; every `main` change must arrive through a
protected pull request with all required checks passing, the branch up to date,
and squash auto-merge enabled. The `main` ruleset has no bypass actors,
including the release App. After GitHub merges the maintenance pull request,
the release App may create a new protected `v*` tag but may not update or delete
one. The
tag-triggered workflow alone publishes through OIDC and creates the GitHub
Release. Never push directly to `main`, move/reuse a release tag, bypass
validation, store long-lived publication credentials, or publish from an
untagged/scheduled job.
