#!/usr/bin/env bash
# Deploy the DNA ML sandbox Azure resources from your own machine.
#
# Usage:
#   az login
#   az account set --subscription "<sandbox subscription>"
#   export DNA_ALERT_EMAIL="platform-team@yourcompany.com"
#   scripts/deploy-sandbox.sh --plan   # preview only
#   scripts/deploy-sandbox.sh          # preview, then asks before applying
#
# You need Owner (or Contributor + Role Based Access Control Administrator) on the subscription,
# and Terraform 1.9 or newer.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${root}"
plan_only=false
[[ "${1:-}" == "--plan" ]] && plan_only=true

# shellcheck source=scripts/config.sh
source scripts/config.sh
stack="infra/azure"

echo "== 1. Tools and login"
command -v terraform >/dev/null || { echo "Install Terraform 1.9+ first." >&2; exit 1; }
sub_name="$(az account show --query name -o tsv)" || { echo "Run 'az login' first." >&2; exit 1; }
ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
export ARM_SUBSCRIPTION_ID
echo "  Subscription: ${sub_name} (${ARM_SUBSCRIPTION_ID})"

echo "== 2. Settings"
if grep -q '"CHANGE-ME"' "${stack}/sandbox.tfvars" "${stack}/backend.sandbox.hcl"; then
  echo "  CHANGE-ME values remain. Run scripts/bootstrap-state.sh and set cost_centre in ${stack}/sandbox.tfvars." >&2
  exit 1
fi
if [[ -z "${DNA_ALERT_EMAIL:-}" ]]; then
  echo "  Set DNA_ALERT_EMAIL to the address that should receive alerts." >&2
  exit 1
fi
export TF_VAR_alert_email="${DNA_ALERT_EMAIL}"
echo "  Alerts go to: ${DNA_ALERT_EMAIL}"

echo "== 3. Entra groups"
# shellcheck source=scripts/get-group-ids.sh
source scripts/get-group-ids.sh

echo "== 4. Terraform init"
terraform -chdir="${stack}" init -input=false -backend-config=backend.sandbox.hcl

echo "== 5. Plan: nothing is changed yet"
terraform -chdir="${stack}" plan -input=false -var-file=sandbox.tfvars -out=sandbox.tfplan

if [[ "${plan_only}" == true ]]; then
  rm -f "${stack}/sandbox.tfplan"
  echo "Preview only. Nothing was changed."
  exit 0
fi

read -r -p "Apply this plan to '${sub_name}'? Type yes to continue: " answer
if [[ "${answer}" != "yes" ]]; then
  rm -f "${stack}/sandbox.tfplan"
  echo "Cancelled. Nothing was changed."
  exit 0
fi

echo "== 6. Apply"
terraform -chdir="${stack}" apply -input=false sandbox.tfplan
rm -f "${stack}/sandbox.tfplan"
terraform -chdir="${stack}" output

echo
echo "Done. Next: scripts/deploy-fabric.sh, then docs/deployment-runbook.md step 7."
