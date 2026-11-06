# Request menu

When the DNA team asks for something, find it here and follow the line.
Day-to-day work (notebooks, training, using approved models) needs **no request**: their group roles already cover it.

| When DNA asks… | We do… | Approval needed | Time |
|---|---|---|---|
| "Add a new person" | Add them to the right `sg-dna-*` group (we're group owners) | Their manager | Minutes (or the agreed identity-team turnaround) |
| "We want to try ML in Fabric" | Already enabled; point them to the workspace | None | Minutes |
| "We want to train a custom model" | Already deployed: Azure ML workspace `mlw-dna-sbx-san-01` with `cpu-cluster` | None | Minutes |
| "We need more CPU nodes" | Raise `cpuClusterMaxNodes` in `infra/sandbox.bicepparam`, run the deploy workflow | Platform lead | Under an hour |
| "We need GPUs" | Request GPU quota, then set `deployGpuCluster = true` and run the deploy workflow | Platform lead + budget owner | Hours (days for quota) |
| "We want to use GPT" | Add the approved model to `foundryModelDeployments`, run the deploy workflow | Security (data and residency check) | Under an hour |
| "We want a model that isn't on the approved list" | Security review of the model, then add it to the list | Security | Days |
| "An app needs the model live" | Azure ML managed online endpoint (containers handled by Azure ML) | Platform lead | Hours |
| "We have our own Docker app" | Container Apps template (not built yet) + CI/CD to the registry | Platform lead + security | About a day |
| "Our sandbox resource group is about to expire" | Update `expires` in `infra/sandbox.bicepparam`, run the deploy workflow | Platform lead | Minutes |
| "We want real patient data in the sandbox" | **No.** Real data needs private networking: plan dev/prod instead | Security | Project |
| "Put it in production" | Follow the [promotion checklist](promotion-checklist.md) | Change board / business owner | Agreed process |

Every change to the platform goes through this repo: edit, open a pull request, let the **Validate** check pass, merge, then run **Deploy sandbox**.
