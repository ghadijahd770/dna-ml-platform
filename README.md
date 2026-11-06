# DNA ML Platform

The machine learning platform for the DNA team: Microsoft Fabric for data, Azure Machine Learning for building models, and Microsoft Foundry for ready-made AI models. Everything is defined here as code, so it's built the same way every time and every change is reviewed.

**Current scope: the sandbox.** Public endpoints, Entra-only login, an Azure ML managed network, and synthetic or masked data only. See the [network decision](docs/network-decision.md).

![Architecture](docs/images/diagram.png)

## What gets built

| Resource group | Contents | Lock | Expires |
|---|---|---|---|
| `rg-dna-shared-sbx-san-01` | Log Analytics, Key Vault, alert action group, access-change alert, CI/CD identity | Delete lock | No (permanent) |
| `rg-dna-ml-sbx-san-01` | Azure ML workspace (managed network), storage, Key Vault, App Insights, container registry, CPU cluster (scales to 0), optional GPU cluster | – | Yes |
| `rg-dna-ai-sbx-san-01` | Foundry resource (API keys off), project, approved model deployments | – | Yes |

Plus: role assignments for the six Entra groups, a monthly budget with 50/80/100% alerts on each resource group, diagnostic logs to Log Analytics, and guardrail policies on the subscription.

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
│   ├── main.bicep                   ← entry point (subscription scope)
│   ├── sandbox.bicepparam           ← sandbox settings: fill in CHANGE-ME values
│   ├── modules/                     ← shared, ml, foundry, budget
│   ├── roles.bicep                  ← built-in role IDs
│   └── types.bicep                  ← parameter types
├── policies/
│   ├── assign-policies.sh           ← assigns the guardrail policies
│   └── README.md
├── scripts/
│   ├── deploy-sandbox.sh            ← preview + deploy from your machine
│   ├── get-group-ids.sh             ← looks up the Entra group IDs
│   ├── check-roles.sh               ← checks role IDs still match Azure
│   ├── sandbox-cleanup-report.sh    ← monthly expiry check
│   └── config.sh                    ← group names and region
└── .github/workflows/
    ├── validate.yml                 ← compiles and lints on every push
    └── deploy-sandbox.yml           ← preview or deploy from GitHub (OIDC, approval required)
```

## Quick start

1. Request the Entra groups: [docs/identity-team-request.md](docs/identity-team-request.md)
2. Fill in the `CHANGE-ME` values in `infra/sandbox.bicepparam`
3. Preview, then deploy:

   ```bash
   az login
   az account set --subscription "<sandbox subscription>"
   export DNA_ALERT_EMAIL="platform-team@yourcompany.com"
   scripts/deploy-sandbox.sh --what-if
   scripts/deploy-sandbox.sh
   ```

4. Assign the policies: `policies/assign-policies.sh`
5. Finish the manual Fabric steps and the GitHub workflow setup: [docs/deployment-runbook.md](docs/deployment-runbook.md)

## How changes work

1. Edit on a branch and open a pull request.
2. **Validate** compiles the Bicep and checks the scripts.
3. Merge, then run **Actions → Deploy sandbox** with *Preview only* ticked, check the preview, then run it again unticked. The `sandbox` environment asks for your approval before anything is deployed.

## Status

The templates compile in GitHub Actions but **have not been deployed to Azure yet**. Run the what-if preview first and expect to fix small things on the first real deployment. Check role IDs with `scripts/check-roles.sh`; `policies/assign-policies.sh` skips and reports any policy name it can't find.
