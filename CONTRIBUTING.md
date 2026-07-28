# Contributing

Use the exact official stable Flutter SDK in `.flutter-version` (currently
3.44.8). This is the development/CI pin, not the minimum supported SDK.

```bash
flutter pub get
dart format .
flutter analyze
flutter test
dart run tool/validate_snapshot.dart
dart pub publish --dry-run
```

## Snapshot work

Do not edit `assets/country_subdivision_data` manually. Use a verified local
checkout:

```bash
dart run tool/generate_snapshot.dart \
  --upstream-path ../countries-states-cities-database
dart run tool/sync_upstream.dart \
  --upstream-path ../countries-states-cities-database
dart run tool/upstream_data_manager.dart check
dart run tool/upstream_data_manager.dart update --dry-run \
  --upstream-path ../countries-states-cities-database
dart run tool/upstream_data_manager.dart verify
```

Generation must preserve ODbL attribution, stable sorting/key order, referential
integrity, and the Nigeria regression: 37 first-level subdivisions, Rivers code
`RI`, and Port Harcourt assigned to Rivers. Optional malformed numbers normalize
to `null`; required records fail generation. Never add fabricated geographic
values.

## SDK and version tools

```bash
dart run tool/flutter_sdk_manager.dart current
dart run tool/flutter_sdk_manager.dart check
dart run tool/flutter_sdk_manager.dart check-major
dart run tool/flutter_sdk_manager.dart update --dry-run
dart run tool/flutter_sdk_manager.dart verify

dart run tool/version_manager.dart current
dart run tool/version_manager.dart next
dart run tool/version_manager.dart bump --reason data --dry-run
dart run tool/version_manager.dart verify
```

Flutter maintenance ignores same-major minor and patch releases, prereleases,
and downgrades. It never mutates a developer's global SDK or automatically
raises package SDK constraints. The package version uses decimal-digit rollover:
`0.0.9 → 0.1.0` and `0.9.9 → 1.0.0`.

## Monthly automated releases

The single monthly workflow checks official Flutter stable metadata and the
verified upstream commit. No meaningful change leaves the repository untouched.
An eligible run applies Flutter-major and/or data changes, validates before and
after exactly one bump, generates a Markdown/JSON release review, commits to the
default branch through a dedicated GitHub App, and pushes an immutable tag.
Only that tag can trigger OIDC publication.

Repository setup must provide:

- `RELEASE_APP_ID` as a repository/organization variable.
- `RELEASE_APP_PRIVATE_KEY` as an encrypted secret.
- `RELEASE_BOT_NOREPLY_EMAIL` as a repository variable.
- A narrowly scoped GitHub App with repository metadata read and contents write.
- A ruleset allowing only that App to push validated releases to the default
  branch and tags; do not disable protection globally.
- Labels `automated-release-failure`, `pub-dev`, and `maintenance`.

The workflow fails if the remote branch advances, credentials are absent, a tag
already exists, validation fails, or candidate data is not meaningful. It never
force-pushes or reuses tags.

## One-time initial publication and OIDC

Automation cannot create a pub.dev package. After reviewing and validating
version `0.0.1`, publish it manually:

```bash
dart pub publish
```

Then open the package Admin page on pub.dev, enable GitHub Actions automated
publishing, and configure exactly:

- Repository: `M-Tayyab-Mustafa/country_subdivision_data`
- Tag pattern: `v{{version}}`
- Environment: `pub.dev`

Create the `pub.dev` GitHub environment without a required reviewer when fully
automatic publishing is intended. Do not store `pub-credentials.json` or a
pub.dev token. Later releases use OIDC. A failed publication keeps its immutable
tag; rerun the same workflow for transient failures, or make source corrections
in a new version/tag.

## Review and licensing

Review generated counts, checksums, size changes, changelog, release audit, and
publication archive. The package source is BSD-3-Clause; generated data remains
ODbL 1.0. Preserve `NOTICE` and upstream notices. Legal interpretation of ODbL
redistribution and produced-work obligations requires human review.
