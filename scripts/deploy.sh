#!/usr/bin/env bash
# Plan, then apply, one part of the platform from your own machine.
#
# Usage:
#   az login
#   az account set --subscription "<sandbox subscription>"
#   scripts/deploy.sh platform [--plan]   # shared foundation (once, then rarely)
#   scripts/deploy.sh requests [--plan]   # team Azure resources from requests/teams/*.yaml
#   scripts/deploy.sh fabric   [--plan]   # team Fabric workspace roles
#
# --plan shows what would change and stops. Without it, you're asked before anything changes.
# Order the first time: platform, then requests, then fabric.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${root}"

part="${1:-}"
plan_only=false
[[ "${2:-}" == "--plan" ]] && plan_only=true

case "${part}" in
  platform) stack="platform" ;;
  requests) stack="requests/azure" ;;
  fabric) stack="requests/fabric" ;;
  *)
    echo "Usage: scripts/deploy.sh platform|requests|fabric [--plan]" >&2
    exit 1
    ;;
esac

command -v terraform >/dev/null || { echo "Install Terraform 1.9 or newer first." >&2; exit 1; }
sub_name="$(az account show --query name -o tsv)" || { echo "Run 'az login' first." >&2; exit 1; }
ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
export ARM_SUBSCRIPTION_ID
export FABRIC_USE_CLI=true

echo "Part:         ${part} (${stack})"
echo "Subscription: ${sub_name}"

# Stop early on settings that still need filling in.
check_files=("${stack}/sandbox.tfvars" "${stack}/backend.sandbox.hcl")
[[ "${part}" != "platform" ]] && check_files+=(requests/teams/*.yaml)
if grep -n 'CHANGE-ME' "${check_files[@]}" | grep -v '^\S*:[0-9]*:\s*#'; then
  echo "Fill in the CHANGE-ME values above first (bootstrap/README.md)." >&2
  exit 1
fi

terraform -chdir="${stack}" init -input=false -backend-config=backend.sandbox.hcl
terraform -chdir="${stack}" plan -input=false -var-file=sandbox.tfvars -out=deploy.tfplan

if [[ "${plan_only}" == true ]]; then
  rm -f "${stack}/deploy.tfplan"
  echo "Plan only. Nothing was changed."
  exit 0
fi

read -r -p "Apply this plan? Type yes to continue: " answer
if [[ "${answer}" != "yes" ]]; then
  rm -f "${stack}/deploy.tfplan"
  echo "Cancelled. Nothing was changed."
  exit 0
fi

terraform -chdir="${stack}" apply -input=false deploy.tfplan
rm -f "${stack}/deploy.tfplan"
terraform -chdir="${stack}" output
