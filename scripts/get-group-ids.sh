#!/usr/bin/env bash
# Look up the object IDs of the six DNA Entra groups and export them for Terraform
# as TF_VAR_group_ids.
#
# Usage (note the "source", so the variable stays in your shell):
#   source scripts/get-group-ids.sh
#
# Reading group IDs needs no admin rights. If your account can't read groups,
# ask the identity team for the object IDs and export TF_VAR_group_ids yourself, e.g.
#   export TF_VAR_group_ids='{"platform_admins":"<id>","data_scientists":"<id>"}'

_dna_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/config.sh
source "${_dna_dir}/config.sh"

_dna_lookup() {
  local group_name="$1" id
  id="$(az ad group show --group "${group_name}" --query id -o tsv 2>/dev/null || true)"
  if [[ -z "${id}" ]]; then
    printf '  %-28s %s\n' "${group_name}" "NOT FOUND (its role assignments will be skipped)" >&2
  else
    printf '  %-28s %s\n' "${group_name}" "${id}" >&2
  fi
  printf '%s' "${id}"
}

echo "Entra group object IDs:" >&2
_dna_pa="$(_dna_lookup "${DNA_GROUP_NAME_PLATFORM_ADMINS}")"
_dna_de="$(_dna_lookup "${DNA_GROUP_NAME_DATA_ENGINEERS}")"
_dna_ds="$(_dna_lookup "${DNA_GROUP_NAME_DATA_SCIENTISTS}")"
_dna_me="$(_dna_lookup "${DNA_GROUP_NAME_ML_ENGINEERS}")"
_dna_ga="$(_dna_lookup "${DNA_GROUP_NAME_GENAI_DEVELOPERS}")"
_dna_vw="$(_dna_lookup "${DNA_GROUP_NAME_VIEWERS}")"

export TF_VAR_group_ids="{\"platform_admins\":\"${_dna_pa}\",\"data_engineers\":\"${_dna_de}\",\"data_scientists\":\"${_dna_ds}\",\"ml_engineers\":\"${_dna_me}\",\"genai_developers\":\"${_dna_ga}\",\"viewers\":\"${_dna_vw}\"}"
unset _dna_pa _dna_de _dna_ds _dna_me _dna_ga _dna_vw
