// DNA ML platform: sandbox environment.
//
// Deploys at SUBSCRIPTION scope and creates:
//   rg-dna-shared-<env>-<region>-01  Log Analytics, Key Vault, alert contacts, CI/CD identity, delete lock
//   rg-dna-ml-<env>-<region>-01      Azure ML workspace (managed network, public endpoint, Entra-only)
//   rg-dna-ai-<env>-<region>-01      Foundry resource + project (public endpoint, API keys off)
// plus a monthly budget on each resource group and role assignments for the Entra groups.
//
// Deploy with scripts/deploy-sandbox.sh or the "Deploy sandbox" GitHub Actions workflow.

targetScope = 'subscription'

import { groupIdsType, modelDeploymentType } from 'types.bicep'
import { roleIds } from 'roles.bicep'

// ── Naming ────────────────────────────────────────────────────────────────────
@description('Azure region. Must match the Fabric capacity region.')
param location string = 'southafricanorth'

@description('Short region code used in names (san = South Africa North).')
@maxLength(4)
param regionCode string = 'san'

@description('Environment code used in names.')
@allowed(['sbx', 'dev', 'tst', 'prd'])
param env string = 'sbx'

@description('Team code used in names.')
param team string = 'dna'

@description('Instance number used in names.')
param instance string = '01'

// ── Tags and cost ─────────────────────────────────────────────────────────────
@description('Owner tag value.')
param owner string

@description('Cost centre tag value.')
param costCentre string

@description('Expiry date (yyyy-mm-dd) tagged on the ML and AI resource groups. Review monthly.')
param expires string

@description('Email address (team mailbox or Teams channel address) that receives alerts.')
param alertEmail string

@description('Monthly budget per resource group, in the billing account currency.')
param monthlyBudget int = 500

@description('Budget start date: the first day of a month, yyyy-MM-01. Keep it fixed after the first deployment.')
param budgetStartDate string

// ── Access ────────────────────────────────────────────────────────────────────
@description('Object IDs of the six Entra groups. Empty values are skipped.')
param groupIds groupIdsType

@description('GitHub repository (owner/name) allowed to deploy with the CI/CD identity.')
param githubRepo string = 'ghadijahd770/dna-ml-platform'

@description('GitHub environment name used by the deploy workflow.')
param githubEnvironment string = 'sandbox'

@description('Give the CI/CD identity Contributor + Role Based Access Control Administrator on the subscription so the deploy workflow can run. Agree this with security.')
param grantCiSubscriptionAccess bool = true

// ── Azure ML ──────────────────────────────────────────────────────────────────
@description('VM size for the CPU training cluster.')
param cpuClusterVmSize string = 'Standard_DS3_v2'

@description('Maximum nodes for the CPU training cluster. Minimum is always 0.')
param cpuClusterMaxNodes int = 2

@description('Create a GPU cluster too. Needs GPU quota in the region first.')
param deployGpuCluster bool = false

@description('VM size for the GPU training cluster.')
param gpuClusterVmSize string = 'Standard_NC4as_T4_v3'

@description('Maximum nodes for the GPU cluster.')
param gpuClusterMaxNodes int = 1

@description('Turn off storage shared keys on the Azure ML storage account. Read docs/network-decision.md first.')
param disableStorageSharedKey bool = false

// ── Foundry ───────────────────────────────────────────────────────────────────
@description('Create the Foundry resource and project.')
param deployFoundry bool = true

@description('Approved model deployments. Only models on this list exist in the sandbox.')
param foundryModelDeployments modelDeploymentType[] = []

// ── Derived values ────────────────────────────────────────────────────────────
var nameSuffix = '${env}-${regionCode}-${instance}'
var baseTags = {
  owner: owner
  env: env == 'sbx' ? 'sandbox' : env
  costcentre: costCentre
  workload: 'dna-ml-platform'
}
var expiringTags = union(baseTags, { expires: expires })

// ── Resource groups ───────────────────────────────────────────────────────────
resource rgShared 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${team}-shared-${nameSuffix}'
  location: location
  tags: baseTags
}

resource rgMl 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${team}-ml-${nameSuffix}'
  location: location
  tags: expiringTags
}

resource rgAi 'Microsoft.Resources/resourceGroups@2024-03-01' = if (deployFoundry) {
  name: 'rg-${team}-ai-${nameSuffix}'
  location: location
  tags: expiringTags
}

// ── Shared foundations ────────────────────────────────────────────────────────
module shared 'modules/shared.bicep' = {
  name: 'dna-shared-${nameSuffix}'
  scope: rgShared
  params: {
    location: location
    team: team
    env: env
    nameSuffix: nameSuffix
    tags: baseTags
    alertEmail: alertEmail
    groupIds: groupIds
    githubRepo: githubRepo
    githubEnvironment: githubEnvironment
  }
}

// ── Azure ML ──────────────────────────────────────────────────────────────────
module ml 'modules/ml.bicep' = {
  name: 'dna-ml-${nameSuffix}'
  scope: rgMl
  params: {
    location: location
    team: team
    env: env
    nameSuffix: nameSuffix
    tags: expiringTags
    logAnalyticsWorkspaceId: shared.outputs.logAnalyticsWorkspaceId
    groupIds: groupIds
    ciPrincipalId: shared.outputs.ciPrincipalId
    cpuClusterVmSize: cpuClusterVmSize
    cpuClusterMaxNodes: cpuClusterMaxNodes
    deployGpuCluster: deployGpuCluster
    gpuClusterVmSize: gpuClusterVmSize
    gpuClusterMaxNodes: gpuClusterMaxNodes
    disableStorageSharedKey: disableStorageSharedKey
  }
}

// ── Foundry ───────────────────────────────────────────────────────────────────
module foundry 'modules/foundry.bicep' = if (deployFoundry) {
  name: 'dna-foundry-${nameSuffix}'
  scope: rgAi
  params: {
    location: location
    team: team
    env: env
    nameSuffix: nameSuffix
    tags: expiringTags
    logAnalyticsWorkspaceId: shared.outputs.logAnalyticsWorkspaceId
    groupIds: groupIds
    ciPrincipalId: shared.outputs.ciPrincipalId
    modelDeployments: foundryModelDeployments
  }
}

// ── Budgets (alerts at 50 / 80 / 100 %) ───────────────────────────────────────
module budgetShared 'modules/budget.bicep' = {
  name: 'dna-budget-shared-${nameSuffix}'
  scope: rgShared
  params: {
    budgetName: 'budget-${rgShared.name}'
    amount: monthlyBudget
    startDate: budgetStartDate
    actionGroupId: shared.outputs.actionGroupId
  }
}

module budgetMl 'modules/budget.bicep' = {
  name: 'dna-budget-ml-${nameSuffix}'
  scope: rgMl
  params: {
    budgetName: 'budget-${rgMl.name}'
    amount: monthlyBudget
    startDate: budgetStartDate
    actionGroupId: shared.outputs.actionGroupId
  }
}

module budgetAi 'modules/budget.bicep' = if (deployFoundry) {
  name: 'dna-budget-ai-${nameSuffix}'
  scope: rgAi
  params: {
    budgetName: 'budget-rg-${team}-ai-${nameSuffix}'
    amount: monthlyBudget
    startDate: budgetStartDate
    actionGroupId: shared.outputs.actionGroupId
  }
}

// ── CI/CD identity on the subscription ────────────────────────────────────────
// Needed so the deploy workflow can create resource groups and role assignments.
resource ciContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (grantCiSubscriptionAccess) {
  name: guid(subscription().id, 'dna-cicd', roleIds.contributor)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.contributor)
    principalId: shared.outputs.ciPrincipalId
    principalType: 'ServicePrincipal'
    description: 'DNA ML platform CI/CD identity: deploys the sandbox templates.'
  }
}

resource ciRbacAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (grantCiSubscriptionAccess) {
  name: guid(subscription().id, 'dna-cicd', roleIds.rbacAdministrator)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.rbacAdministrator)
    principalId: shared.outputs.ciPrincipalId
    principalType: 'ServicePrincipal'
    description: 'DNA ML platform CI/CD identity: creates the role assignments in the templates.'
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────
output sharedResourceGroup string = rgShared.name
output mlResourceGroup string = rgMl.name
output aiResourceGroup string = deployFoundry ? 'rg-${team}-ai-${nameSuffix}' : ''
output mlWorkspaceName string = ml.outputs.workspaceName
output mlStorageAccountName string = ml.outputs.storageAccountName
output foundryAccountName string = deployFoundry ? foundry!.outputs.accountName : ''
output foundryProjectName string = deployFoundry ? foundry!.outputs.projectName : ''
output keyVaultName string = shared.outputs.keyVaultName
output ciClientId string = shared.outputs.ciClientId
output ciPrincipalId string = shared.outputs.ciPrincipalId
