// Azure Machine Learning workspace for the DNA team.
// Sandbox network decision: public endpoint + Entra-only login + Microsoft-managed network.

import { groupIdsType } from '../types.bicep'
import { roleIds } from '../roles.bicep'

param location string
param team string
param env string
param nameSuffix string
param tags object
param logAnalyticsWorkspaceId string
param groupIds groupIdsType
param ciPrincipalId string
param cpuClusterVmSize string
param cpuClusterMaxNodes int
param deployGpuCluster bool
param gpuClusterVmSize string
param gpuClusterMaxNodes int
param disableStorageSharedKey bool

var unique = take(uniqueString(resourceGroup().id), 8)

// ── Workspace storage ────────────────────────────────────────────────────────
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: toLower('st${team}ml${env}${unique}')
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: !disableStorageSharedKey
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

// ── Workspace Key Vault (used by Azure ML itself) ────────────────────────────
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${team}-ml-${env}-${take(unique, 6)}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
  }
}

// ── Monitoring ───────────────────────────────────────────────────────────────
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${team}-ml-${nameSuffix}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

// ── Container registry: model images, Entra login only (admin user off) ─────
resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: toLower('cr${team}ml${env}${unique}')
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

// ── Workspace ────────────────────────────────────────────────────────────────
resource workspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: 'mlw-${team}-${nameSuffix}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'DNA ML ${env}'
    description: 'DNA team Azure ML workspace (${env}).'
    storageAccount: storage.id
    keyVault: keyVault.id
    applicationInsights: appInsights.id
    containerRegistry: registry.id
    publicNetworkAccess: 'Enabled'
    managedNetwork: {
      isolationMode: 'AllowInternetOutbound'
    }
  }
}

resource workspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-log-analytics'
  scope: workspace
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

// ── Compute: scales to zero, so you only pay while training ─────────────────
resource cpuCluster 'Microsoft.MachineLearningServices/workspaces/computes@2024-04-01' = {
  parent: workspace
  name: 'cpu-cluster'
  location: location
  properties: {
    computeType: 'AmlCompute'
    disableLocalAuth: true
    properties: {
      vmSize: cpuClusterVmSize
      vmPriority: 'Dedicated'
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: cpuClusterMaxNodes
        nodeIdleTimeBeforeScaleDown: 'PT120S'
      }
    }
  }
}

resource gpuCluster 'Microsoft.MachineLearningServices/workspaces/computes@2024-04-01' = if (deployGpuCluster) {
  parent: workspace
  name: 'gpu-cluster'
  location: location
  properties: {
    computeType: 'AmlCompute'
    disableLocalAuth: true
    properties: {
      vmSize: gpuClusterVmSize
      vmPriority: 'Dedicated'
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: gpuClusterMaxNodes
        nodeIdleTimeBeforeScaleDown: 'PT120S'
      }
    }
  }
}

// ── Permissions (docs/permissions.md) ────────────────────────────────────────
var rgAssignments = filter(
  [
    { principalId: groupIds.dataEngineers, roleId: roleIds.reader, principalType: 'Group' }
    { principalId: groupIds.dataScientists, roleId: roleIds.reader, principalType: 'Group' }
    { principalId: groupIds.mlEngineers, roleId: roleIds.reader, principalType: 'Group' }
    { principalId: groupIds.viewers, roleId: roleIds.reader, principalType: 'Group' }
  ],
  a => !empty(a.principalId)
)

var workspaceAssignments = filter(
  [
    { principalId: groupIds.platformAdmins, roleId: roleIds.owner, principalType: 'Group' }
    { principalId: groupIds.dataScientists, roleId: roleIds.azureMlDataScientist, principalType: 'Group' }
    { principalId: groupIds.dataScientists, roleId: roleIds.azureMlComputeOperator, principalType: 'Group' }
    { principalId: groupIds.mlEngineers, roleId: roleIds.azureMlDataScientist, principalType: 'Group' }
    { principalId: groupIds.mlEngineers, roleId: roleIds.azureMlComputeOperator, principalType: 'Group' }
    { principalId: ciPrincipalId, roleId: roleIds.contributor, principalType: 'ServicePrincipal' }
  ],
  a => !empty(a.principalId)
)

var storageAssignments = filter(
  [
    { principalId: groupIds.platformAdmins, roleId: roleIds.storageBlobDataContributor, principalType: 'Group' }
    { principalId: groupIds.dataScientists, roleId: roleIds.storageBlobDataContributor, principalType: 'Group' }
    { principalId: groupIds.dataScientists, roleId: roleIds.storageFileDataPrivilegedContributor, principalType: 'Group' }
    { principalId: groupIds.mlEngineers, roleId: roleIds.storageBlobDataContributor, principalType: 'Group' }
    { principalId: groupIds.mlEngineers, roleId: roleIds.storageFileDataPrivilegedContributor, principalType: 'Group' }
    { principalId: ciPrincipalId, roleId: roleIds.storageBlobDataContributor, principalType: 'ServicePrincipal' }
  ],
  a => !empty(a.principalId)
)

var registryAssignments = filter(
  [
    { principalId: groupIds.mlEngineers, roleId: roleIds.acrPull, principalType: 'Group' }
    { principalId: ciPrincipalId, roleId: roleIds.acrPush, principalType: 'ServicePrincipal' }
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

resource workspaceRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for a in workspaceAssignments: {
    name: guid(workspace.id, a.principalId, a.roleId)
    scope: workspace
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', a.roleId)
      principalId: a.principalId
      principalType: a.principalType
    }
  }
]

resource storageRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for a in storageAssignments: {
    name: guid(storage.id, a.principalId, a.roleId)
    scope: storage
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', a.roleId)
      principalId: a.principalId
      principalType: a.principalType
    }
  }
]

resource registryRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for a in registryAssignments: {
    name: guid(registry.id, a.principalId, a.roleId)
    scope: registry
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', a.roleId)
      principalId: a.principalId
      principalType: a.principalType
    }
  }
]

output workspaceName string = workspace.name
output workspaceId string = workspace.id
output workspacePrincipalId string = workspace.identity.principalId
output storageAccountName string = storage.name
output registryName string = registry.name
