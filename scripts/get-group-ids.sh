#!/usr/bin/env bash
# Look up the object IDs of the six DNA Entra groups and export them for the deployment.
#
# Usage (note the "source", so the variables stay in your shell):
#   source scripts/get-group-ids.sh
#
# Reading group IDs needs no admin rights. If your account can't read groups,
# ask the identity team for the object IDs and export the DNA_GROUP_* variables yourself.

_dna_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/config.sh
source "${_dna_dir}/config.sh"

_dna_lookup() {
  local var_name="$1" group_name="$2" id
  id="$(az ad group show --group "${group_name}" --query id -o tsv 2>/dev/null || true)"
  if [[ -z "${id}" ]]; then
    printf '  %-28s %s\n' "${group_name}" "NOT FOUND (its role assignments will be skipped)"
  else
    printf '  %-28s %s\n' "${group_name}" "${id}"
  fi
  export "${var_name}=${id}"
}

echo "Entra group object IDs:"
_dna_lookup DNA_GROUP_PLATFORM_ADMINS  "${DNA_GROUP_NAME_PLATFORM_ADMINS}"
_dna_lookup DNA_GROUP_DATA_ENGINEERS   "${DNA_GROUP_NAME_DATA_ENGINEERS}"
_dna_lookup DNA_GROUP_DATA_SCIENTISTS  "${DNA_GROUP_NAME_DATA_SCIENTISTS}"
_dna_lookup DNA_GROUP_ML_ENGINEERS     "${DNA_GROUP_NAME_ML_ENGINEERS}"
_dna_lookup DNA_GROUP_GENAI_DEVELOPERS "${DNA_GROUP_NAME_GENAI_DEVELOPERS}"
_dna_lookup DNA_GROUP_VIEWERS          "${DNA_GROUP_NAME_VIEWERS}"
