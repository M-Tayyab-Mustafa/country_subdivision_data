#!/usr/bin/env bash
set -euo pipefail

: "${GH_TOKEN:?GH_TOKEN with repository Administration write is required}"
: "${RELEASE_APP_ID:?RELEASE_APP_ID is required}"

repository="${GITHUB_REPOSITORY:-M-Tayyab-Mustafa/country_subdivision_data}"
api="repos/$repository"

upsert_ruleset() {
  local file="$1"
  local name id
  name="$(jq -r .name "$file")"
  id="$(gh api "$api/rulesets?includes_parents=false" \
    --jq ".[] | select(.name == \"$name\") | .id" | head -n 1)"
  if [ -n "$id" ]; then
    gh api --method PUT "$api/rulesets/$id" --input "$file" >/dev/null
  else
    gh api --method POST "$api/rulesets" --input "$file" >/dev/null
  fi
}

tag_creation_rules="$(mktemp)"
trap 'rm -f "$tag_creation_rules"' EXIT

upsert_ruleset .github/rulesets/main.json
upsert_ruleset .github/rulesets/release-tags-immutable.json

jq --argjson app_id "$RELEASE_APP_ID" '{
  name: "Release tag creation",
  target: "tag",
  enforcement: "active",
  bypass_actors: [{
    actor_id: $app_id,
    actor_type: "Integration",
    bypass_mode: "always"
  }],
  conditions: {
    ref_name: {
      include: ["refs/tags/v*"],
      exclude: []
    }
  },
  rules: [{type: "creation"}]
}' >"$tag_creation_rules"
upsert_ruleset "$tag_creation_rules"

gh api --method PATCH "$api" \
  -F allow_auto_merge=true \
  -F allow_squash_merge=true \
  -F allow_merge_commit=false \
  -F allow_rebase_merge=false \
  -F delete_branch_on_merge=false >/dev/null

echo "Active main and release-tag policy configured for $repository."
