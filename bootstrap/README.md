# Bootstrap: once-off setup

Do these steps **once**, in order, when setting up the sandbox. After that, everything happens through [`requests/`](../requests/) and the [request menu](../docs/request-menu.md).

## What you need first

| You need | From |
|---|---|
| The six Entra groups, with you as owner | Identity team: send [identity-team-request.md](identity-team-request.md) |
| Owner on the sandbox subscription (or Contributor + Role Based Access Control Administrator) | Subscription owner |
| Admin on the DNA sandbox Fabric workspace; a Fabric admin for tenant settings | Fabric admin |
| Security sign-off on [permissions](../docs/permissions.md) and the [network decision](../docs/network-decision.md) | Security team |
| Azure CLI, **Terraform 1.9 or newer**, Git and Bash (Git Bash or WSL on Windows) | Install yourself |

## 1. Get the code and log in

```bash
git clone https://github.com/ghadijahd770/dna-ml-platform.git
cd dna-ml-platform
az login
az account set --subscription "<sandbox subscription name or id>"
```

## 2. Create the Terraform state storage

Terraform keeps a record of what it built, called the **state file**. It lives in a locked-down storage account, not on your laptop.

```bash
bootstrap/bootstrap-state.sh
```

It fills the storage account name into the six settings files it lists. **Commit them.**

## 3. Get the group IDs

```bash
bootstrap/get-group-ids.sh
```

Paste the output: the platform admins ID into `platform/sandbox.tfvars`, and the `groups:` block into `requests/teams/dna.yaml`.

## 4. Fill in the settings

| File | Set |
|---|---|
| `platform/sandbox.tfvars` | `cost_centre`, `alert_email`, `budget_start_date` (first day of this month) |
| `requests/teams/dna.yaml` | `cost_centre`, `expires`, `fabric.workspace_id` (the GUID after `/groups/` in the Fabric workspace URL) |

## 5. Deploy the platform foundation

```bash
scripts/deploy.sh platform --plan
scripts/deploy.sh platform
```

Note the `ci_client_id` output for step 9. Commit `platform/.terraform.lock.hcl`, which Terraform creates the first time.

## 6. Deploy the DNA team's resources

```bash
scripts/deploy.sh requests --plan
scripts/deploy.sh requests
scripts/deploy.sh fabric --plan
scripts/deploy.sh fabric
```

Commit `requests/azure/.terraform.lock.hcl` and `requests/fabric/.terraform.lock.hcl`.

## 7. Assign the guardrail policies

```bash
bootstrap/assign-policies.sh
```

See [policies.md](policies.md) for what each one does and how to move from Audit to Deny.

## 8. Fabric settings that stay manual

1. **Tenant settings** (Fabric admin portal): enable the Data Science / machine learning settings for the DNA groups only.
2. **Lakehouse in another workspace:** if the landed data lives in a different workspace, share that lakehouse with `sg-dna-data-scientists` with *Read all data*.
3. **Git integration:** connect the DNA workspace to a repo.
4. **Environments:** create a Fabric Environment with the libraries the team uses, so everyone gets the same versions.
5. **Sensitivity labels:** with the Purview / compliance team, make sure labels can be applied to lakehouses and reports.
6. **Capacity alerts:** Admin portal → Capacity settings → Notifications, alert at 80%.

## 9. Set up the GitHub deploy workflow

1. **Settings → Environments → New environment** `sandbox`. Add yourself as a **required reviewer**.
2. **Settings → Secrets and variables → Actions → Variables**:

| Variable | Value |
|---|---|
| `AZURE_CLIENT_ID` | `ci_client_id` from step 5 |
| `AZURE_TENANT_ID` | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | `az account show --query id -o tsv` |

3. **Actions → Deploy → Run workflow**, part `requests`, *Plan only* ticked. It should report **No changes**.

## 10. Test it

Run the sandbox test in the [promotion checklist](../docs/promotion-checklist.md). Then tell the DNA team the platform is ready and point them at the request forms (**Issues → New issue**).
