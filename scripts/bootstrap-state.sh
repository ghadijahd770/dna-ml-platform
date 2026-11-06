#!/usr/bin/env bash
# One-time setup: create the secure storage account where Terraform keeps its state.
#
# Terraform records what it has built in a "state file". This script creates:
#   rg-dna-tfstate-sbx-san-01            resource group (tagged, delete lock)
#   stdnatfstate<8 characters>           storage account: Entra-only, no public access, versioning on
#   tfstate                              container for the state files
# and fills the storage account name into the backend and tfvars files.
#
# Usage:
#   az login && az account set --subscription "<sandbox subscription>"
#   scripts/bootstrap-state.sh
# Then commit the changed backend.sandbox.hcl and sandbox.tfvars files.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/config.sh
source "${root}/scripts/config.sh"

sub_id="$(az account show --query id -o tsv)" || { echo "Run 'az login' first." >&2; exit 1; }
sub_name="$(az account show --query name -o tsv)"
me="$(az ad signed-in-user show --query id -o tsv)"
rg="rg-dna-tfstate-sbx-san-01"
sa="stdnatfstate$(printf '%s' "${sub_id}" | md5sum | cut -c1-8)"

echo "Subscription:    ${sub_name}"
echo "Resource group:  ${rg}"
echo "Storage account: ${sa}"
read -r -p "Create these? Type yes to continue: " answer
[[ "${answer}" == "yes" ]] || { echo "Cancelled."; exit 0; }

az group create --name "${rg}" --location "${DNA_LOCATION}" \
  --tags owner=dna-platform env=sandbox costcentre=platform workload=dna-ml-platform >/dev/null

az storage account create --name "${sa}" --resource-group "${rg}" --location "${DNA_LOCATION}" \
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 \
  --allow-blob-public-access false --allow-shared-key-access false \
  --tags owner=dna-platform env=sandbox costcentre=platform workload=dna-ml-platform >/dev/null

az storage account blob-service-properties update --account-name "${sa}" --resource-group "${rg}" \
  --enable-versioning true --enable-delete-retention true --delete-retention-days 30 >/dev/null

sa_id="$(az storage account show --name "${sa}" --resource-group "${rg}" --query id -o tsv)"
az role assignment create --assignee-object-id "${me}" --assignee-principal-type User \
  --role "Storage Blob Data Contributor" --scope "${sa_id}" >/dev/null || true

echo "Waiting for the new permission to take effect..."
for _ in $(seq 1 12); do
  if az storage container create --name tfstate --account-name "${sa}" --auth-mode login >/dev/null 2>&1; then
    break
  fi
  sleep 10
done
az storage container show --name tfstate --account-name "${sa}" --auth-mode login >/dev/null

az lock create --name do-not-delete --resource-group "${rg}" --lock-type CanNotDelete \
  --notes "Terraform state for the DNA ML platform." >/dev/null

for f in infra/azure/backend.sandbox.hcl infra/fabric/backend.sandbox.hcl; do
  sed -i.bak -E "s/^storage_account_name = \".*\"/storage_account_name = \"${sa}\"/" "${root}/${f}" && rm -f "${root}/${f}.bak"
done
sed -i.bak -E "s/^tfstate_storage_account_name = \".*\"/tfstate_storage_account_name = \"${sa}\"/" \
  "${root}/infra/azure/sandbox.tfvars" && rm -f "${root}/infra/azure/sandbox.tfvars.bak"

echo
echo "Done. State storage is ready: ${sa}"
echo "Commit these files: infra/azure/backend.sandbox.hcl infra/fabric/backend.sandbox.hcl infra/azure/sandbox.tfvars"
