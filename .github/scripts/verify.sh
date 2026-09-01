#!/usr/bin/env bash
set -euo pipefail

verify_release_review=true
if [ "$#" -gt 1 ]; then
  echo "Usage: $0 [--pre-release]" >&2
  exit 64
fi
case "${1:-}" in
  '') ;;
  '--pre-release') verify_release_review=false ;;
  *)
    echo "Usage: $0 [--pre-release]" >&2
    exit 64
    ;;
esac

flutter --version
flutter doctor -v
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run tool/validate_snapshot.dart
dart run tool/flutter_sdk_manager.dart verify
dart run tool/upstream_data_manager.dart verify
dart run tool/version_manager.dart verify
if [ "$verify_release_review" = true ]; then
  dart run tool/verify_release_review.dart
fi
bash .github/scripts/check_publish_dry_run.sh
