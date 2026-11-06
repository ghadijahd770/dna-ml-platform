#!/usr/bin/env bash
# ONCE-OFF: create the secure storage account where Terraform keeps its state.
#
# Terraform records what it has built in "state files". This script creates:
#   rg-dna-tfstate-sbx-san-01            resource group (tagged, delete lock)
#   stdnatfstate<8 characters>           storage account: Entra-only, no public blobs, versioning on
#   tfstate                              container for the state files
# and fills the storage account name into every backend.sandbox.hcl and sandbox.tfvars.
#
# Usage:
#   az login && az account set --subscription "<sandbox subscription>"
#   bootstrap/bootstrap-state.sh
# Then commit the changed files it lists.
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

tags=(owner=dna-platform env=sandbox costcentre=platform workload=dna-ml-platform)

az group create --name "${rg}" --location "${DNA_LOCATION}" --tags "${tags[@]}" >/dev/null

az storage account create --name "${sa}" --resource-group "${rg}" --location "${DNA_LOCATION}" \
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 \
  --allow-blob-public-access false --allow-shared-key-access false \
  --tags "${tags[@]}" >/dev/null

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

changed=(
  platform/backend.sandbox.hcl
  platform/sandbox.tfvars
  requests/azure/backend.sandbox.hcl
  requests/azure/sandbox.tfvars
  requests/fabric/backend.sandbox.hcl
  requests/fabric/sandbox.tfvars
)
for f in "${changed[@]}"; do
  sed -i.bak -E \
    -e "s/^storage_account_name( *)= \".*\"/storage_account_name\1= \"${sa}\"/" \
    -e "s/^tfstate_storage_account_name( *)= \".*\"/tfstate_storage_account_name\1= \"${sa}\"/" \
    "${root}/${f}"
  rm -f "${root}/${f}.bak"
done

echo
echo "Done. State storage is ready: ${sa}"
echo "Commit these files:"
printf '  %s\n' "${changed[@]}"
