## 0.0.3

### Automation

- Repaired release validation for the current GitHub-hosted Ubuntu runner.
- Made automated failure reporting create its required labels.

### Validation

- Passed formatting, analysis, tests, snapshot integrity, Nigeria regression, and pub.dev publication dry-run.

## 0.0.2

### Data

- Updated the country, subdivision, and city snapshot.
- Preserved verified upstream commit `81d127720a3da919c5d3da95a662316626a1ce49` while normalizing deterministic snapshot encoding.

### Reliability and release automation

- Made gzip snapshot generation byte-identical across macOS and Linux.
- Added an active pull-request-only release design with strict required checks,
  branch refresh, and squash auto-merge.
- Added post-merge release-tag verification and tag-only pub.dev OIDC
  publication.
- Corrected CI formatting and pull-request version-policy validation.

### Validation

- Passed formatting, analysis, tests, snapshot integrity, Nigeria regression, and pub.dev publication dry-run.

## 0.0.1

- Initial development release.
- Added country, subdivision, and city models.
- Added lazy per-country snapshot loading.
- Added search and lookup APIs.
- Added a customizable country-aware phone form field.
- Added a customizable searchable country-picker dialog.
- Added deterministic upstream snapshot generation.
- Added snapshot integrity validation.
- Added fully automated monthly Flutter-major and upstream-data releases.
- Added Nigeria regression coverage for Rivers State and Port Harcourt.
