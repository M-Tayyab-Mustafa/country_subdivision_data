#!/usr/bin/env bash
set -euo pipefail

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
dart pub publish --dry-run
