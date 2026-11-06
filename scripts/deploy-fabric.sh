#!/usr/bin/env bash
# Give the DNA groups (and Azure ML) their roles on the Fabric sandbox workspace.
#
# Usage:
#   az login
#   az account set --subscription "<sandbox subscription>"   # for the state storage
#   scripts/deploy-fabric.sh --plan   # preview only
#   scripts/deploy-fabric.sh          # preview, then asks before applying
#
# You must be an Admin of the Fabric workspace. Run scripts/deploy-sandbox.sh first
# so the Azure ML workspace identity exists.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${root}"
plan_only=false
[[ "${1:-}" == "--plan" ]] && plan_only=true
stack="infra/fabric"

command -v terraform >/dev/null || { echo "Install Terraform 1.9+ first." >&2; exit 1; }
az account show >/dev/null || { echo "Run 'az login' first." >&2; exit 1; }
ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
export ARM_SUBSCRIPTION_ID
export FABRIC_USE_CLI=true

if grep -q '"CHANGE-ME"' "${stack}/sandbox.tfvars" "${stack}/backend.sandbox.hcl"; then
  echo "CHANGE-ME values remain in ${stack}. Set workspace_id and run scripts/bootstrap-state.sh." >&2
  exit 1
fi

# shellcheck source=scripts/get-group-ids.sh
source scripts/get-group-ids.sh

echo "Reading the Azure ML workspace identity from the Azure stack..."
terraform -chdir=infra/azure init -input=false -backend-config=backend.sandbox.hcl >/dev/null
TF_VAR_aml_workspace_principal_id="$(terraform -chdir=infra/azure output -raw ml_workspace_principal_id 2>/dev/null || true)"
export TF_VAR_aml_workspace_principal_id
[[ -n "${TF_VAR_aml_workspace_principal_id}" ]] || echo "  Not found: Azure ML won't get Fabric access yet. Run scripts/deploy-sandbox.sh first."

terraform -chdir="${stack}" init -input=false -backend-config=backend.sandbox.hcl
terraform -chdir="${stack}" plan -input=false -var-file=sandbox.tfvars -out=fabric.tfplan

if [[ "${plan_only}" == true ]]; then
  rm -f "${stack}/fabric.tfplan"
  echo "Preview only. Nothing was changed."
  exit 0
fi

read -r -p "Apply these Fabric workspace roles? Type yes to continue: " answer
if [[ "${answer}" != "yes" ]]; then
  rm -f "${stack}/fabric.tfplan"
  echo "Cancelled. Nothing was changed."
  exit 0
fi

terraform -chdir="${stack}" apply -input=false fabric.tfplan
rm -f "${stack}/fabric.tfplan"
echo "Done."
