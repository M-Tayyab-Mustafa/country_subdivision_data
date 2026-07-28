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
after exactly one bump, generates a Markdown/JSON release review, and pushes
only `automation/monthly-maintenance`. It opens or updates a pull request to
`main`, refreshes the automation branch whenever `main` changes, and enables
squash auto-merge. After GitHub merges that pull request, a separate workflow
verifies the commit on `main` and the dedicated release GitHub App creates the
immutable tag. Only that tag can trigger OIDC publication.

Repository setup must provide:

- `RELEASE_APP_ID` as a repository/organization variable.
- `RELEASE_APP_PRIVATE_KEY` as an encrypted secret.
- `RELEASE_BOT_NOREPLY_EMAIL` as a repository variable.
- A narrowly scoped GitHub App with repository metadata read, contents write,
  and pull requests write.
- Active `main` protection with an empty bypass list, pull-request-only changes,
  zero human approvals, conversation resolution, strict required checks, linear
  history, and force-push/deletion protection. The bypass list must remain
  empty.
- Auto-merge enabled, with squash as the only allowed merge method.
- Immutable `v*` tag protection with no update/deletion bypass. A separate tag
  creation rule permits only the dedicated release GitHub App.
- Labels `automated-release-failure`, `pub-dev`, and `maintenance`.

Apply the checked-in repository policy with an administration-capable token:

```bash
GH_TOKEN=... RELEASE_APP_ID=... \
  bash .github/scripts/configure_repository.sh
```

The workflow refreshes its open pull-request branch and reruns required checks
when `main` advances. It fails if credentials are absent, a tag already exists,
validation fails, or candidate data is not meaningful. It may replace only its
dedicated maintenance branch using a lease-protected update; it never pushes
directly to `main`, bypasses the `main` ruleset, force-updates a release tag, or
reuses a tag.

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
