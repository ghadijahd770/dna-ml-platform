# Permissions

Who gets what in the DNA ML sandbox. Access is always given to **Entra groups**, never to individual people.
Terraform creates every role assignment below automatically, including the Fabric workspace roles. Only the Fabric "Read all data" permission on a lakehouse in another workspace is set by hand.

Team roles are assigned in [`requests/modules/team-azure/roles.tf`](../requests/modules/team-azure/roles.tf) and platform roles in [`platform/roles.tf`](../platform/roles.tf), by role **name**, so Terraform stops with a clear error if Microsoft renames one. Fabric workspace roles are assigned in [`requests/fabric/main.tf`](../requests/fabric/main.tf). Group object IDs live in each team file, `requests/teams/<team>.yaml`.

## By group

| Group | Fabric workspace | Azure ML workspace | Azure ML storage account | Foundry | Container registry | Key Vault |
|---|---|---|---|---|---|---|
| `sg-dna-platform-admins` | Admin | Owner | Storage Blob Data Contributor | Azure AI Account Owner | (subscription Owner) | Key Vault Administrator |
| `sg-dna-data-engineers` | Member | Reader (resource group) | – | – | – | – |
| `sg-dna-data-scientists` | Contributor | AzureML Data Scientist + AzureML Compute Operator | Storage Blob Data Contributor + Storage File Data Privileged Contributor | Azure AI User (project) | – | – |
| `sg-dna-ml-engineers` | Contributor | AzureML Data Scientist + AzureML Compute Operator | Storage Blob Data Contributor + Storage File Data Privileged Contributor | Azure AI User (project) | AcrPull | Key Vault Secrets User |
| `sg-dna-genai-developers` | Viewer | – | – | Azure AI User (project) | – | – |
| `sg-dna-viewers` | Viewer | Reader (resource group) | – | Reader (resource group) | – | – |
| CI/CD identity `id-dna-cicd-sbx-san-01` | Contributor (if it deploys Fabric items) | Contributor | Storage Blob Data Contributor | Azure AI User | AcrPush | Key Vault Secrets User |
| App / running model identity | Contributor (only if it reads OneLake) | – | – | Cognitive Services OpenAI User | AcrPull | Key Vault Secrets User |

Data scientists, ML engineers and viewers also get **Reader** on `rg-dna-ml-sbx-san-01`, and the Foundry users get **Reader** on `rg-dna-ai-sbx-san-01`, so they can see resources in the Azure portal without changing anything.

The CI/CD identity also gets **Contributor** and **Role Based Access Control Administrator** on the subscription (`grant_ci_subscription_access = true` in `platform/sandbox.tfvars`) so the deploy workflow can create resource groups and role assignments. Agree this with security. It also gets access to the Terraform state storage. Set `grant_ci_subscription_access = false` to keep all deployments manual.

## Why the storage roles matter

The sandbox is Entra-only. Azure ML studio opens files and notebooks with the person's own login. Without the two storage roles, data scientists get "access denied" on their data and notebooks.

## Data scientist access in full

| Where | Role | Assigned on | Lets them |
|---|---|---|---|
| Fabric | Contributor | The DNA sandbox workspace | Create notebooks, experiments, ML models and pipelines |
| Fabric (data) | Viewer + Read all data | The lakehouse with the landed data, if it's in a different workspace | Read the data without changing it |
| Azure ML | AzureML Data Scientist | The Azure ML workspace | Run training, track experiments, register models, deploy to test endpoints |
| Azure ML | AzureML Compute Operator | The Azure ML workspace | Create, start and stop their own compute |
| Azure ML storage | Storage Blob Data Contributor | The workspace storage account | Upload and read data files |
| Azure ML storage | Storage File Data Privileged Contributor | The workspace storage account | Use the notebook file share on their compute |
| Foundry | Azure AI User | The Foundry project | Use the approved models, build and test |
| Azure portal | Reader | `rg-dna-ml-sbx-san-01`, `rg-dna-ai-sbx-san-01` | See the resources, change nothing |

**Data scientists must not have:** Owner, Contributor or User Access Administrator on any resource group or the subscription; Key Vault access; AcrPush; or permission to deploy new Foundry models.

## How the services reach each other

- **Azure ML reads Fabric data:** `requests/fabric` gives the Azure ML workspace identity Contributor on the Fabric workspace.
- **Azure ML reaches its own storage, Key Vault and registry** through its managed identity. Azure sets this up when the workspace is created.
- **An app calls a Foundry model** using its managed identity with *Cognitive Services OpenAI User*. No API keys.
- **An endpoint pulls its container** from the registry with *AcrPull*.

## Expensive compute

Azure ML compute isn't covered by the normal "allowed VM sizes" policy. The control is **quota**: the sandbox has no GPU quota until someone has an approved need. Without quota, nobody can start a GPU.
