# Guardrail policies

`assign-policies.sh` assigns these Azure Policy built-ins to the sandbox subscription. A policy stops a mistake; an alert only tells you afterwards.

| Policy | What it stops | Effect at start |
|---|---|---|
| Allowed locations | Resources created outside South Africa North | Deny (built in) |
| Allowed locations for resource groups | Resource groups created outside South Africa North | Deny (built in) |
| Require a tag on resource groups (owner, env, costcentre) | Resource groups nobody owns | Deny (built in) |
| Inherit a tag from the resource group if missing (owner, env, costcentre) | Untagged resources in cost reports | Modify (adds the tag) |
| Azure Machine Learning compute instances should have idle shutdown | Computers left running all weekend | Audit |
| Azure Machine Learning Computes should have local authentication methods disabled | Logging in to compute without Entra | Audit |
| Azure AI Services resources should have key access disabled | Foundry models called with a copied API key | Audit |
| Storage accounts should prevent shared key access | Storage opened with a shared key | Audit |
| Container registries should have local admin account disabled | Registry opened with an admin password | Audit |
| Key vaults should have deletion protection enabled | Secrets lost forever | Audit |

## Audit first, then Deny

Audit only reports. After a week, check **Policy → Compliance**. If nothing important is flagged, change an assignment to Deny:

```bash
az policy assignment update --name dna-ai-no-keys --params '{"effect":{"value":"Deny"}}'
```

Not every policy supports Deny. The portal shows the allowed effects for each one.

## Things to know

- These assignments cover the **whole subscription**. If other teams share it, agree with the subscription owner first.
- The storage shared-key policy will report the Azure ML storage account as non-compliant until `disable_storage_shared_key` is turned on (see [network decision](../docs/network-decision.md)).
- "Inherit a tag" only tags new or changed resources. For existing ones, create a **remediation task** in Policy → Remediation.
- Azure ML compute isn't covered by the "allowed VM sizes" policy. GPU cost is controlled by **quota**: the sandbox has none until approved.
- Policy display names change occasionally. The script skips any it can't find and says so. Search the portal for a similar name.
