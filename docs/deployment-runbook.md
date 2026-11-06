# Deployment runbook: DNA ML sandbox

Follow these steps in order the first time. After that, every change goes through a pull request and the **Deploy sandbox** workflow.

The platform is built with **Terraform** in two parts:

| Stack | Folder | What it manages | Who runs it |
|---|---|---|---|
| Azure | `infra/azure` | Resource groups, Azure ML, Foundry, Key Vault, logs, alerts, budgets, CI/CD identity, Azure role assignments | You first, then the GitHub workflow |
| Fabric | `infra/fabric` | Fabric workspace roles for the groups, and Azure ML's access to OneLake | A Fabric workspace admin (you) |

## 0. Before you start

| You need | From |
|---|---|
| The six Entra groups, with you as owner | Identity team ([request](identity-team-request.md)) |
| Owner on the sandbox subscription (or Contributor + Role Based Access Control Administrator) | Subscription owner |
| Admin on the DNA sandbox Fabric workspace; a Fabric admin for tenant settings | Fabric admin |
| Security sign-off on [permissions](permissions.md) and the [network decision](network-decision.md) | Security team |
| Azure CLI, **Terraform 1.9 or newer**, Git and Bash (Git Bash or WSL on Windows) | Install yourself |

## 1. Get the code

```bash
git clone https://github.com/ghadijahd770/dna-ml-platform.git
cd dna-ml-platform
```

## 2. Create the Terraform state storage (once)

Terraform keeps a record of what it built, called the **state file**. It lives in a locked-down storage account, not on your laptop.

```bash
az login
az account set --subscription "<sandbox subscription name or id>"
scripts/bootstrap-state.sh
```

This creates `rg-dna-tfstate-sbx-san-01` with an Entra-only storage account, versioning and a delete lock, then fills its name into the backend files. **Commit the three changed files.**

## 3. Fill in the settings

- `infra/azure/sandbox.tfvars`: set `cost_centre` (required) and check `expires`, `monthly_budget` and `budget_start_date` (first day of the current month).
- `infra/fabric/sandbox.tfvars`: set `workspace_id`, the GUID after `/groups/` in the Fabric workspace URL.
- If the identity team renamed the groups, update `scripts/config.sh`.

## 4. Preview, then deploy the Azure stack

```bash
export DNA_ALERT_EMAIL="platform-team@yourcompany.com"
scripts/deploy-sandbox.sh --plan
scripts/deploy-sandbox.sh
```

The plan lists everything that would be created. Nothing changes until you type `yes`. It takes about 10–15 minutes. Note the `ci_client_id` output.

Terraform creates a `.terraform.lock.hcl` file in `infra/azure` the first time. **Commit it**, so everyone uses the same provider versions.

## 5. Deploy the Fabric stack

```bash
scripts/deploy-fabric.sh --plan
scripts/deploy-fabric.sh
```

This gives each group its Fabric workspace role and gives Azure ML Contributor on the workspace so it can read OneLake. Commit `infra/fabric/.terraform.lock.hcl` too.

## 6. Assign the guardrail policies

```bash
policies/assign-policies.sh
```

See [`policies/README.md`](../policies/README.md) for what each policy does and how to move from Audit to Deny.

## 7. Fabric settings that stay manual

1. **Tenant settings** (Fabric admin portal): enable the Data Science / machine learning settings for the DNA groups only.
2. **Lakehouse in another workspace:** if the landed data lives in a different workspace, share that lakehouse with `sg-dna-data-scientists` with *Read all data*.
3. **Git integration:** connect the DNA workspace to a repo.
4. **Capacity alerts:** Admin portal → Capacity settings → Notifications, alert at 80%.

Public endpoints mean Fabric needs **no managed private endpoints** in the sandbox.

## 8. Set up the GitHub deploy workflow

1. **Settings → Environments → New environment** `sandbox`. Add yourself as a **required reviewer**.
2. **Settings → Secrets and variables → Actions → Variables** and add:

| Variable | Value |
|---|---|
| `AZURE_CLIENT_ID` | `ci_client_id` from step 4 |
| `AZURE_TENANT_ID` | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | `az account show --query id -o tsv` |
| `DNA_ALERT_EMAIL` | the alert address |
| `DNA_GROUP_PLATFORM_ADMINS` … `DNA_GROUP_VIEWERS` | printed by `source scripts/get-group-ids.sh` |

3. **Actions → Deploy sandbox → Run workflow** with *Plan only* ticked. It should log in and report **No changes**.

## 9. Test it

Run the sandbox test in the [promotion checklist](promotion-checklist.md).

## Every month

```bash
scripts/sandbox-cleanup-report.sh
```

Ask the owner of anything expired to extend it (update `expires`) or delete it.

## Rules for working with Terraform

- **Never change platform resources in the portal.** Terraform will undo the change on the next apply, or the plan will show surprising differences. Change the code instead.
- **Always read the plan** before applying. Watch for anything marked `destroy` or `must be replaced`.
- **Never delete or edit the state file** by hand.

## Tearing the sandbox down

The shared resource group has a **delete lock** managed by Terraform. Set the lock aside deliberately before `terraform destroy`, and only with platform team approval. The shared Key Vault has purge protection, so its name stays reserved for 90 days after deletion.
