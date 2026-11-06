#!/usr/bin/env bash
# Deploy the DNA ML sandbox from your own machine (first deployment, or any time).
#
# Usage:
#   az login
#   az account set --subscription "<sandbox subscription>"
#   export DNA_ALERT_EMAIL="platform-team@yourcompany.com"
#   scripts/deploy-sandbox.sh            # preview, then asks before deploying
#   scripts/deploy-sandbox.sh --what-if  # preview only
#
# You need Owner (or Contributor + Role Based Access Control Administrator) on the subscription.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${root}"
what_if_only=false
[[ "${1:-}" == "--what-if" ]] && what_if_only=true

# shellcheck source=scripts/config.sh
source scripts/config.sh

echo "== 1. Azure login"
sub_name="$(az account show --query name -o tsv)" || { echo "Run 'az login' first." >&2; exit 1; }
sub_id="$(az account show --query id -o tsv)"
echo "  Subscription: ${sub_name} (${sub_id})"

echo "== 2. Settings"
if grep -q "CHANGE-ME'" infra/sandbox.bicepparam; then
  echo "  infra/sandbox.bicepparam still has CHANGE-ME values. Fill them in first." >&2
  exit 1
fi
if [[ -z "${DNA_ALERT_EMAIL:-}" ]]; then
  echo "  Set DNA_ALERT_EMAIL to the address that should receive alerts." >&2
  exit 1
fi
echo "  Alerts go to: ${DNA_ALERT_EMAIL}"

echo "== 3. Entra groups"
# shellcheck source=scripts/get-group-ids.sh
source scripts/get-group-ids.sh

echo "== 4. Role IDs"
scripts/check-roles.sh

deployment="dna-sandbox-$(date +%Y%m%d-%H%M%S)"

echo "== 5. Preview (what-if): nothing is changed yet"
az deployment sub what-if \
  --name "${deployment}" \
  --location "${DNA_LOCATION}" \
  --parameters infra/sandbox.bicepparam

if [[ "${what_if_only}" == true ]]; then
  echo "Preview only. Nothing was deployed."
  exit 0
fi

read -r -p "Deploy these changes to '${sub_name}'? Type yes to continue: " answer
if [[ "${answer}" != "yes" ]]; then
  echo "Cancelled. Nothing was deployed."
  exit 0
fi

echo "== 6. Deploy"
az deployment sub create \
  --name "${deployment}" \
  --location "${DNA_LOCATION}" \
  --parameters infra/sandbox.bicepparam \
  --query properties.outputs -o json

echo
echo "Done. Next steps are in docs/deployment-runbook.md (step 5 onwards)."
