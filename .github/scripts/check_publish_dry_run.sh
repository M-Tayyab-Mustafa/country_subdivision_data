#!/usr/bin/env bash
set -euo pipefail

repository="$(git rev-parse --show-toplevel)"
candidate="$(mktemp -d)"
trap 'rm -rf "$candidate"' EXIT

# pub treats modified tracked files as a fatal warning. Maintenance must
# validate its exact candidate before committing it, so copy every tracked or
# publishable untracked file into a clean, temporary repository first.
while IFS= read -r -d '' path; do
  if [ ! -e "$repository/$path" ] && [ ! -L "$repository/$path" ]; then
    continue
  fi
  mkdir -p "$candidate/$(dirname "$path")"
  cp -p "$repository/$path" "$candidate/$path"
done < <(
  git -C "$repository" ls-files \
    --cached \
    --others \
    --exclude-standard \
    -z
)

git -C "$candidate" init --quiet
git -C "$candidate" add --all
git -C "$candidate" \
  -c user.name=country-subdivision-data-validation \
  -c user.email=validation@localhost \
  commit --quiet --allow-empty \
  --message='Validate publication candidate'

(
  cd "$candidate"
  dart pub publish --dry-run
)
