#!/usr/bin/env bash
# Assign the DNA sandbox guardrails (Azure Policy built-ins) to the subscription.
#
# Usage:
#   az login && az account set --subscription "<sandbox subscription>"
#   policies/assign-policies.sh
#
# Policies are looked up by display name (with or without a trailing full stop), so no long IDs are needed. A policy that
# can't be found is reported and skipped. Everything except "allowed locations",
# "require a tag" and "inherit a tag" starts in Audit mode: it reports, it doesn't block.
# After a week with no surprises, change the effect to Deny (see policies/README.md).
#
# These assignments apply to the WHOLE subscription. If other teams share it,
# agree this with the subscription owner first.
set -euo pipefail

location="${DNA_LOCATION:-southafricanorth}"
sub_id="$(az account show --query id -o tsv)"
sub_name="$(az account show --query name -o tsv)"
scope="/subscriptions/${sub_id}"

echo "About to assign DNA sandbox policies to subscription: ${sub_name}"
read -r -p "Type yes to continue: " answer
[[ "${answer}" == "yes" ]] || { echo "Cancelled."; exit 0; }

lookup() {
  az policy definition list \
    --query "[?policyType=='BuiltIn' && (displayName=='$1' || displayName=='$1.')] | [0].name" -o tsv 2>/dev/null
}

# assign <display name> <assignment name> <params JSON or ""> [extra az args...]
assign() {
  local display="$1" name="$2" params="$3"
  shift 3
  local def
  def="$(lookup "${display}")"
  if [[ -z "${def}" ]]; then
    echo "  SKIP  ${display} (not found; search the portal for a similar name)"
    return 0
  fi
  local args=(--name "${name}" --display-name "DNA: ${display}" --policy "${def}" --scope "${scope}")
  [[ -n "${params}" ]] && args+=(--params "${params}")
  if az policy assignment create "${args[@]}" "$@" >/dev/null; then
    echo "  OK    ${display}"
  else
    echo "  FAIL  ${display}"
  fi
}

echo "Where and what:"
assign "Allowed locations" "dna-allowed-locations" \
  "{\"listOfAllowedLocations\":{\"value\":[\"${location}\"]}}"
assign "Allowed locations for resource groups" "dna-allowed-rg-locations" \
  "{\"listOfAllowedLocations\":{\"value\":[\"${location}\"]}}"

echo "Ownership tags:"
for tag in owner env costcentre; do
  assign "Require a tag on resource groups" "dna-require-rg-tag-${tag}" \
    "{\"tagName\":{\"value\":\"${tag}\"}}"
  assign "Inherit a tag from the resource group if missing" "dna-inherit-tag-${tag}" \
    "{\"tagName\":{\"value\":\"${tag}\"}}" \
    --mi-system-assigned --location "${location}" \
    --role "Tag Contributor" --identity-scope "${scope}"
done

echo "Cost:"
assign "Azure Machine Learning compute instances should have idle shutdown" "dna-aml-idle-shutdown" \
  '{"effect":{"value":"Audit"}}'

echo "Entra-only login (no keys or admin passwords):"
assign "Azure Machine Learning Computes should have local authentication methods disabled" "dna-aml-no-local-auth" \
  '{"effect":{"value":"Audit"}}'
assign "Azure AI Services resources should have key access disabled (disable local authentication)" "dna-ai-no-keys" \
  '{"effect":{"value":"Audit"}}'
assign "Storage accounts should prevent shared key access" "dna-storage-no-shared-key" \
  '{"effect":{"value":"Audit"}}'
assign "Container registries should have local admin account disabled" "dna-acr-no-admin" \
  '{"effect":{"value":"Audit"}}'

echo "Protection:"
assign "Key vaults should have deletion protection enabled" "dna-kv-deletion-protection" \
  '{"effect":{"value":"Audit"}}'

echo
echo "Done. Check compliance in the portal: Policy > Compliance. Existing resources"
echo "missing tags need a remediation task (Policy > Remediation)."
