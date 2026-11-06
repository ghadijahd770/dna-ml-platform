#!/usr/bin/env bash
# Monthly sandbox clean-up check: lists sandbox resource groups and flags expired ones.
# It only reports. Nothing is deleted.
set -euo pipefail

today="$(date +%Y-%m-%d)"
echo "Sandbox resource groups (today is ${today}):"
printf '  %-32s %-12s %-20s %s\n' "RESOURCE GROUP" "EXPIRES" "OWNER" "STATUS"

az group list \
  --query "[?tags.env=='sandbox'].[name, tags.expires, tags.owner]" -o tsv |
while IFS=$'\t' read -r name expires owner; do
  if [[ -z "${expires}" || "${expires}" == "None" ]]; then
    status="no expiry (permanent)"
    expires="-"
  elif [[ "${expires}" < "${today}" ]]; then
    status="EXPIRED: ask owner to extend or delete"
  else
    status="ok"
  fi
  printf '  %-32s %-12s %-20s %s\n' "${name}" "${expires}" "${owner:-?}" "${status}"
done
