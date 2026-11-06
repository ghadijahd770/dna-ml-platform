#!/usr/bin/env bash
# Look up the object IDs of the DNA Entra groups and print them ready to paste:
#   - the platform admins ID goes in platform/sandbox.tfvars
#   - the groups block goes in requests/teams/dna.yaml
#
# Usage:
#   az login
#   bootstrap/get-group-ids.sh
#
# Reading group IDs needs no admin rights. If your account can't read groups,
# ask the identity team for the object IDs instead. They are not secrets.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/config.sh
source "${root}/scripts/config.sh"

lookup() {
  az ad group show --group "$1" --query id -o tsv 2>/dev/null || true
}

missing=0
line() {
  local key="$1" name="$2" id note=""
  id="$(lookup "${name}")"
  if [[ -z "${id}" ]]; then
    missing=1
    note="  (NOT FOUND)"
  fi
  printf '  %-18s "%s"   # %s%s\n' "${key}:" "${id}" "${name}" "${note}"
}

pa="$(lookup "${DNA_GROUP_NAME_PLATFORM_ADMINS}")"
pa_note=""
[[ -z "${pa}" ]] && pa_note="  (NOT FOUND)"
echo "── platform/sandbox.tfvars ──"
echo "platform_admins_group_id = \"${pa}\"   # ${DNA_GROUP_NAME_PLATFORM_ADMINS}${pa_note}"
echo
echo "── requests/teams/dna.yaml ──"
echo "groups:"
line data_engineers   "${DNA_GROUP_NAME_DATA_ENGINEERS}"
line data_scientists  "${DNA_GROUP_NAME_DATA_SCIENTISTS}"
line ml_engineers     "${DNA_GROUP_NAME_ML_ENGINEERS}"
line genai_developers "${DNA_GROUP_NAME_GENAI_DEVELOPERS}"
line viewers          "${DNA_GROUP_NAME_VIEWERS}"

if [[ -z "${pa}" || "${missing}" -ne 0 ]]; then
  echo
  echo "Some groups weren't found. Their access is skipped until you add the IDs." >&2
fi
