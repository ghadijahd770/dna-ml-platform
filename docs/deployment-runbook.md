# Deployment runbook: DNA ML sandbox

Follow these steps in order the first time. After that, every change goes through a pull request and the **Deploy sandbox** workflow.

## 0. Before you start

| You need | From |
|---|---|
| The six Entra groups, with you as owner | Identity team ([request](identity-team-request.md)) |
| Owner on the sandbox subscription (or Contributor + Role Based Access Control Administrator) | Subscription owner |
| Fabric admin rights, or a Fabric admin to help | Fabric admin |
| Security sign-off on [permissions](permissions.md) and the [network decision](network-decision.md) | Security team |
| Azure CLI, Git and Bash (Git Bash or WSL on Windows) | Install yourself |

## 1. Get the code

```bash
git clone https://github.com/ghadijahd770/dna-ml-platform.git
cd dna-ml-platform
```

## 2. Fill in the settings

Open `infra/sandbox.bicepparam`. Replace `CHANGE-ME` and check the other values:

- `costCentre`: your cost centre (required)
- `expires`: a date about three months out
- `monthlyBudget`: per resource group, in your billing currency
- `budgetStartDate`: the first day of the current month

If the identity team renamed the groups, update the names in `scripts/config.sh`.

## 3. Log in and preview

```bash
az login
az account set --subscription "<sandbox subscription name or id>"
export DNA_ALERT_EMAIL="platform-team@yourcompany.com"
scripts/deploy-sandbox.sh --what-if
```

The preview lists everything that would be created. Nothing changes yet.

## 4. Deploy

```bash
scripts/deploy-sandbox.sh
```

Type `yes` when asked. It takes about 10–15 minutes. Save the outputs, especially `ciClientId`.

## 5. Assign the guardrail policies

```bash
policies/assign-policies.sh
```

See [`policies/README.md`](../policies/README.md) for what each policy does and how to move from Audit to Deny.

## 6. Fabric (manual)

1. **Tenant settings** (Fabric admin portal): enable the Data Science / machine learning settings for the DNA groups only.
2. **Workspace access:** add the groups with the Fabric roles in [permissions](permissions.md).
3. **Git integration:** connect the DNA workspace to a repo.
4. **Azure ML access to OneLake:** add the Azure ML workspace identity (`mlw-dna-sbx-san-01`) to the Fabric workspace as Contributor.
5. **Capacity alerts:** Admin portal → Capacity settings → Notifications, alert at 80%.

Public endpoints mean Fabric needs **no managed private endpoints** in the sandbox.

## 7. Set up the GitHub deploy workflow

1. **Settings → Environments → New environment** `sandbox`. Add yourself as a **required reviewer**.
2. **Settings → Secrets and variables → Actions → Variables** and add:

| Variable | Value |
|---|---|
| `AZURE_CLIENT_ID` | `ciClientId` from step 4 |
| `AZURE_TENANT_ID` | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | `az account show --query id -o tsv` |
| `DNA_ALERT_EMAIL` | the alert address |
| `DNA_GROUP_PLATFORM_ADMINS` … `DNA_GROUP_VIEWERS` | printed by `source scripts/get-group-ids.sh` |

3. **Actions → Deploy sandbox → Run workflow** with *Preview only* ticked. It should log in and show "no change" for everything.

## 8. Test it

Run the sandbox test in the [promotion checklist](promotion-checklist.md).

## Every month

```bash
scripts/sandbox-cleanup-report.sh
```

Ask the owner of anything expired to extend it (update `expires`) or delete it.

## Tearing the sandbox down

The shared resource group has a **delete lock**. Remove it first, deliberately:

```bash
az lock delete --name do-not-delete --resource-group rg-dna-shared-sbx-san-01
```

The shared Key Vault has purge protection, so its name stays reserved for 90 days after deletion.
