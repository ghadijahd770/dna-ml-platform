// Built-in Azure role definition IDs used by the DNA ML platform.
// These GUIDs are the same in every Azure tenant.
// Run scripts/check-roles.sh to confirm each ID still matches the role name in the comment.

@export()
var roleIds = {
  owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
  reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader
  rbacAdministrator: 'f58310d9-a9f6-439a-9e8d-f62e7b41a168' // Role Based Access Control Administrator
  azureMlDataScientist: 'f6c7c914-8db3-469d-8ca1-694a8f32e121' // AzureML Data Scientist
  azureMlComputeOperator: 'e503ece1-11d0-4e8e-8e2c-7a6c3bf38815' // AzureML Compute Operator
  storageBlobDataContributor: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
  storageFileDataPrivilegedContributor: '69566ab7-960f-475b-8e7c-b3118f30c6bd' // Storage File Data Privileged Contributor
  acrPull: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
  acrPush: '8311e382-0749-4cb8-b61a-304f252e45ec' // AcrPush
  keyVaultAdministrator: '00482a5a-887f-4fb3-b363-3b7fe8e74483' // Key Vault Administrator
  keyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
  azureAiAccountOwner: 'e47c6f54-e4a2-4754-9501-8e0985b135e1' // Azure AI Account Owner
  azureAiUser: '53ca6127-db72-4b80-b1b0-d745d6d5456d' // Azure AI User
  cognitiveServicesOpenAiUser: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Cognitive Services OpenAI User
}
