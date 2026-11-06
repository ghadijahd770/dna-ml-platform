// Microsoft Foundry resource and project for the DNA team.
// Sandbox network decision: public endpoint + API keys off (Entra login only).
// Only the model deployments listed in the parameter file exist; nobody else can add models.

import { groupIdsType, modelDeploymentType } from '../types.bicep'
import { roleIds } from '../roles.bicep'

param location string
param team string
param env string
param nameSuffix string
param tags object
param logAnalyticsWorkspaceId string
param groupIds groupIdsType
param ciPrincipalId string
param modelDeployments modelDeploymentType[]

var accountName = 'aif-${team}-${env}-${take(uniqueString(resourceGroup().id), 6)}'

// ── Foundry resource ─────────────────────────────────────────────────────────
resource account 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: accountName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: accountName
    allowProjectManagement: true
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// ── Project: one per team or use case ────────────────────────────────────────
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: account
  name: 'proj-${team}-${nameSuffix}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'DNA ${env} project'
    description: 'DNA team Foundry project (${env}).'
  }
}

// ── Approved model deployments (one at a time, as the service requires) ─────
@batchSize(1)
resource deployments 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = [
  for d in modelDeployments: {
    parent: account
    name: d.name
    sku: {
      name: d.sku
      capacity: d.capacity
    }
    properties: {
      model: {
        format: d.format
        name: d.model
        version: d.version
      }
    }
  }
]

resource accountDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-log-analytics'
  scope: account
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ── Permissions (docs/permissions.md) ────────────────────────────────────────
var rgAssignments = filter(
  [
    { principalId: groupIds.dataScientists, roleId: roleIds.reader, principalType: 'Group' }
    { principalId: groupIds.mlEngineers, roleId: roleIds.reader, principalType: 'Group' }
    { principalId: groupIds.genaiDevelopers, roleId: roleIds.reader, principalType: 'Group' }
    { principalId: groupIds.viewers, roleId: roleIds.reader, principalType: 'Group' }
  ],
  a => !empty(a.principalId)
)

var accountAssignments = filter(
  [
    { principalId: groupIds.platformAdmins, roleId: roleIds.azureAiAccountOwner, principalType: 'Group' }
    { principalId: ciPrincipalId, roleId: roleIds.azureAiUser, principalType: 'ServicePrincipal' }
  ],
  a => !empty(a.principalId)
)

var projectAssignments = filter(
  [
    { principalId: groupIds.dataScientists, roleId: roleIds.azureAiUser, principalType: 'Group' }
    { principalId: groupIds.mlEngineers, roleId: roleIds.azureAiUser, principalType: 'Group' }
    { principalId: groupIds.genaiDevelopers, roleId: roleIds.azureAiUser, principalType: 'Group' }
  ],
  a => !empty(a.principalId)
)

resource rgRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for a in rgAssignments: {
    name: guid(resourceGroup().id, a.principalId, a.roleId)
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', a.roleId)
      principalId: a.principalId
      principalType: a.principalType
    }
  }
]

resource accountRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for a in accountAssignments: {
    name: guid(account.id, a.principalId, a.roleId)
    scope: account
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', a.roleId)
      principalId: a.principalId
      principalType: a.principalType
    }
  }
]

resource projectRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for a in projectAssignments: {
    name: guid(project.id, a.principalId, a.roleId)
    scope: project
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', a.roleId)
      principalId: a.principalId
      principalType: a.principalType
    }
  }
]

output accountName string = account.name
output projectName string = project.name
output endpoint string = account.properties.endpoint
