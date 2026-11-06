# DNA ML Platform

The machine learning platform for the DNA team: Microsoft Fabric for data, Azure Machine Learning for building models, and Microsoft Foundry for ready-made AI models. Everything is defined here as code with **Terraform**, so it's built the same way every time and every change is reviewed.

**Current scope: the sandbox.** Public endpoints, Entra-only login, an Azure ML managed network, and synthetic or masked data only. See the [network decision](docs/network-decision.md).

![Architecture](docs/images/diagram.png)

## What gets built

| Resource group | Contents | Lock | Expires |
|---|---|---|---|
| `rg-dna-shared-sbx-san-01` | Log Analytics, Key Vault, alert action group, access-change alert, CI/CD identity | Delete lock | No (permanent) |
| `rg-dna-ml-sbx-san-01` | Azure ML workspace (managed network), storage, Key Vault, App Insights, container registry, CPU cluster (scales to 0), optional GPU cluster | – | Yes |
| `rg-dna-ai-sbx-san-01` | Foundry resource (API keys off), project, approved model deployments | – | Yes |

Plus: Azure and Fabric role assignments for the six Entra groups, a monthly budget with 50/80/100% alerts on each resource group, diagnostic logs to Log Analytics, and guardrail policies on the subscription.

## Repository layout

```text
dna-ml-platform/
├── docs/
│   ├── DNA-ML-Platform-Guide.docx   ← full beginner guide (Word)
│   ├── guide.md                     ← the same guide in Markdown
│   ├── deployment-runbook.md        ← how to deploy this repo, step by step
│   ├── permissions.md               ← who gets which role
│   ├── network-decision.md          ← sandbox network choices and when to go private
│   ├── request-menu.md              ← "if DNA asks for X, we do Y"
│   ├── identity-team-request.md     ← email to request the Entra groups
│   └── promotion-checklist.md       ← sandbox → production, plus the test run
├── infra/
│   ├── azure/                       ← Terraform: Azure resources and role assignments
│   │   ├── main.tf, shared.tf, ml.tf, foundry.tf, budgets.tf, roles.tf, outputs.tf
│   │   ├── sandbox.tfvars           ← sandbox settings: fill in CHANGE-ME values
│   │   └── backend.sandbox.hcl      ← where the state file lives
│   └── fabric/                      ← Terraform: Fabric workspace roles
│       ├── main.tf, variables.tf, outputs.tf
│       ├── sandbox.tfvars           ← the Fabric workspace ID
│       └── backend.sandbox.hcl
├── policies/
│   ├── assign-policies.sh           ← assigns the guardrail policies
│   └── README.md
├── scripts/
│   ├── bootstrap-state.sh           ← one-time: secure storage for the Terraform state
│   ├── deploy-sandbox.sh            ← plan + apply the Azure stack from your machine
│   ├── deploy-fabric.sh             ← plan + apply the Fabric workspace roles
│   ├── get-group-ids.sh             ← looks up the Entra group IDs
│   ├── sandbox-cleanup-report.sh    ← monthly expiry check
│   └── config.sh                    ← group names and region
└── .github/workflows/
    ├── validate.yml                 ← terraform fmt + validate and shellcheck on every push
    └── deploy-sandbox.yml           ← plan or apply from GitHub (OIDC, approval required)
```

## Quick start

You need the Azure CLI, **Terraform 1.9+** and Bash.

1. Request the Entra groups: [docs/identity-team-request.md](docs/identity-team-request.md)
2. Create the Terraform state storage (once): `scripts/bootstrap-state.sh`
3. Fill in `cost_centre` in `infra/azure/sandbox.tfvars` and `workspace_id` in `infra/fabric/sandbox.tfvars`
4. Preview, then deploy:

   ```bash
   az login
   az account set --subscription "<sandbox subscription>"
   export DNA_ALERT_EMAIL="platform-team@yourcompany.com"
   scripts/deploy-sandbox.sh --plan
   scripts/deploy-sandbox.sh
   scripts/deploy-fabric.sh
   ```

5. Assign the policies: `policies/assign-policies.sh`
6. Finish the manual Fabric steps and the GitHub workflow setup: [docs/deployment-runbook.md](docs/deployment-runbook.md)

## How changes work

1. Edit on a branch and open a pull request.
2. **Validate** checks the Terraform formatting, runs `terraform validate` on both stacks and checks the scripts.
3. Merge, then run **Actions → Deploy sandbox** with *Plan only* ticked, read the plan, then run it again unticked. The `sandbox` environment asks for your approval before anything changes.

Never change platform resources in the Azure portal: Terraform will undo it. Change the code.

## Status

The Terraform passes `terraform validate` in GitHub Actions but **has not been applied to Azure yet**. Run the plan first and expect to fix small things on the first real deployment. `policies/assign-policies.sh` skips and reports any policy name it can't find.
