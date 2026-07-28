#!/usr/bin/env bash
set -euo pipefail

upstream_path="${1:?upstream checkout path is required}"
first=".tool_work/determinism_first"
second=".tool_work/determinism_second"

rm -rf ".tool_work/determinism_first" ".tool_work/determinism_second"
mkdir -p ".tool_work"
dart run tool/generate_snapshot.dart \
  --upstream-path "$upstream_path" \
  --output "$first"
dart run tool/generate_snapshot.dart \
  --upstream-path "$upstream_path" \
  --output "$second"
diff -qr "$first" "$second"
diff -qr "$first" "assets/country_subdivision_data"
rm -rf ".tool_work/determinism_first" ".tool_work/determinism_second"
