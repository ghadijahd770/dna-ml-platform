#!/usr/bin/env bash
# Confirm every role ID in infra/roles.bicep still matches the role name in its comment.
# Run after `az login`. Exits 1 if any role is missing or renamed.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

echo "Checking built-in role IDs in infra/roles.bicep..."
while IFS= read -r line; do
  id="$(sed -E "s/.*'([0-9a-f-]{36})'.*/\1/" <<<"${line}")"
  expected="$(sed -E 's#.*// ##' <<<"${line}")"
  actual="$(az role definition list --name "${id}" --query '[0].roleName' -o tsv 2>/dev/null || true)"
  if [[ "${actual}" == "${expected}" ]]; then
    printf '  OK    %-45s %s\n' "${expected}" "${id}"
  else
    printf '  FAIL  %-45s %s (Azure says: %s)\n' "${expected}" "${id}" "${actual:-not found}"
    fail=1
  fi
done < <(grep -E "'[0-9a-f-]{36}' // " "${root}/infra/roles.bicep")

if [[ "${fail}" -ne 0 ]]; then
  echo "Some role IDs don't match. Fix infra/roles.bicep before deploying." >&2
  exit 1
fi
echo "All role IDs match."
