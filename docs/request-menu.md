# Request menu

When the DNA team asks for something, find it here and follow the line. They ask through **Issues → New issue**, which has a form for each kind of request.

Day-to-day work (notebooks, training, using approved models) needs **no request**: their group roles already cover it.

## Requests handled in `requests/teams/<team>.yaml`

Change the line, open a pull request, merge, then run **Deploy → requests** (plan, then apply). See [requests/README.md](../requests/README.md).

| When they ask… | Change in the team file | Approval | Time |
|---|---|---|---|
| "We need more CPU nodes" | `azure_ml.cpu_cluster.max_nodes` | Platform lead | Under an hour |
| "We need GPUs" | Request GPU quota first, then `azure_ml.gpu_cluster.enabled: true` | Platform lead + budget owner | Hours (days for quota) |
| "We want to use GPT" (or another model) | Add an entry under `foundry.models` | Security (data and residency) | Under an hour after sign-off |
| "We need another Foundry project" | Add an entry under `foundry.projects` | Platform lead | Under an hour |
| "Our sandbox is about to expire" | `expires` | Platform lead | Minutes |
| "We need a bigger budget" | `monthly_budget` | Budget owner | Minutes |
| "Give group X a different Fabric role" | `fabric.roles`, then `scripts/deploy.sh fabric` | Platform lead | Minutes |
| "A new team wants to join" | Copy `dna.yaml` to `<newteam>.yaml` and fill it in | Platform lead + budget owner | Hours (waiting on groups) |

## Requests handled outside the repo

| When they ask… | We do… | Approval | Time |
|---|---|---|---|
| "Add or remove a person" | Add or remove them in the right `sg-dna-*` group (we're group owners). Azure and Fabric access follow automatically. | Their manager | Minutes |
| "We want a model that isn't approved" | Security review first, then it's a `foundry.models` change | Security | Days |
| "We want real patient data in the sandbox" | **No.** Real data needs private networking: plan dev/prod instead | Security | Project |
| "Put it in production" | Follow the [promotion checklist](promotion-checklist.md) | Change board / business owner | Agreed process |

## Not built yet

| When they ask… | Status |
|---|---|
| "An app needs the model as a live API" (online endpoint) | Needs a template in `requests/modules/` |
| "We have our own Docker app" (Container Apps) | Needs a template in `requests/modules/` |
| "Our app needs to call GPT" (app identity access) | Needs a template in `requests/modules/` |

## Platform changes (rare)

Changes to the shared foundation (alert email, CI/CD access, shared budget) are made in `platform/sandbox.tfvars` and deployed with **Deploy → platform**. Only the platform team does this.
