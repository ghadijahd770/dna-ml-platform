# Requests: day-to-day changes

This is where the menu requests land. **Each team is one YAML file** in [`teams/`](teams/). Change the file, and the platform changes to match.

```text
requests/
├── teams/dna.yaml          ← everything the DNA team has (edit this for requests)
├── azure/                  ← Terraform that turns team files into Azure resources
├── fabric/                 ← Terraform that turns team files into Fabric workspace roles
└── modules/team-azure/     ← what one team gets: Azure ML, Foundry, budgets, roles
```

## How every request works

1. A request comes in as a GitHub issue (**Issues → New issue** has a form for each kind).
2. Make the change on a branch, usually one or two lines in `teams/<team>.yaml`.
3. Open a pull request that says `Closes #<issue number>`. **Validate** checks it.
4. Merge, then **Actions → Deploy**, part `requests`: run once with *Plan only*, read the plan, then run again unticked and approve.
5. If Fabric roles changed: `scripts/deploy.sh fabric` (needs a Fabric workspace admin).

[docs/request-menu.md](../docs/request-menu.md) lists exactly which line to change for each request.

## Adding a new team

1. Copy `teams/dna.yaml` to `teams/<newteam>.yaml`. The file name becomes part of every resource name, so keep it short and lowercase.
2. Ask the identity team for the new team's groups, and put their IDs in the file.
3. Set `owner`, `cost_centre`, `expires`, and the Fabric `workspace_id`.
4. Pull request, merge, deploy `requests`, then `scripts/deploy.sh fabric`.

## Removing something

Delete the lines (or the whole team file) and deploy. **Read the plan carefully**: anything marked `destroy` will be deleted, including its data.
