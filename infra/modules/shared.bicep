// Shared foundations used by every other part of the platform:
// Log Analytics, Key Vault, the alert action group, an activity-log alert on
// access changes, the CI/CD managed identity, and a delete lock on this resource group.

import { groupIdsType } from '../types.bicep'
import { roleIds } from '../roles.bicep'

param location string
param team string
param env string
param nameSuffix string
param tags object
param alertEmail string
param groupIds groupIdsType
param githubRepo string
param githubEnvironment string

var unique = take(uniqueString(resourceGroup().id), 6)

// ── Log Analytics: one place for every log and alert ─────────────────────────
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${team}-${nameSuffix}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ── Key Vault: team secrets. Entra (RBAC) access only. ──────────────────────
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${team}-${env}-${unique}'
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
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
  }
}

resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-log-analytics'
  scope: keyVault
  properties: {
    workspaceId: logAnalytics.id
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

// ── Action group: who gets told when an alert fires ─────────────────────────
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${team}-platform-${nameSuffix}'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: '${team}plat'
    enabled: true
    emailReceivers: [
      {
        name: 'platform-team'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

// ── Alert: someone created or removed a role assignment in the subscription ─
resource accessChangeAlert 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: 'alert-${team}-access-change-${nameSuffix}'
  location: 'global'
  tags: tags
  properties: {
    description: 'A role assignment was created or deleted in the subscription.'
    enabled: true
    scopes: [
      subscription().id
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'Administrative'
        }
        {
          anyOf: [
            {
              field: 'operationName'
              equals: 'Microsoft.Authorization/roleAssignments/write'
            }
            {
              field: 'operationName'
              equals: 'Microsoft.Authorization/roleAssignments/delete'
            }
          ]
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actionGroup.id
        }
      ]
    }
  }
}

// ── CI/CD identity: GitHub Actions logs in with OIDC, no password ───────────
resource ciIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${team}-cicd-${nameSuffix}'
  location: location
  tags: tags
}

resource ciGithubCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: ciIdentity
  name: 'github-${githubEnvironment}'
  properties: {
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:${githubRepo}:environment:${githubEnvironment}'
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

// ── Key Vault permissions ────────────────────────────────────────────────────
var keyVaultAssignments = filter(
  [
    { principalId: groupIds.platformAdmins, roleId: roleIds.keyVaultAdministrator, principalType: 'Group' }
    { principalId: groupIds.mlEngineers, roleId: roleIds.keyVaultSecretsUser, principalType: 'Group' }
  ],
  a => !empty(a.principalId)
)

resource keyVaultRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for a in keyVaultAssignments: {
    name: guid(keyVault.id, a.principalId, a.roleId)
    scope: keyVault
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', a.roleId)
      principalId: a.principalId
      principalType: a.principalType
    }
  }
]

resource ciKeyVaultSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, ciIdentity.id, roleIds.keyVaultSecretsUser)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.keyVaultSecretsUser)
    principalId: ciIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ── Delete lock: protects the logs and Key Vault everything depends on ──────
resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'do-not-delete'
  properties: {
    level: 'CanNotDelete'
    notes: 'Shared DNA platform foundations (logs, Key Vault, alerts, CI/CD identity). Remove this lock only with platform team approval.'
  }
}

output logAnalyticsWorkspaceId string = logAnalytics.id
output actionGroupId string = actionGroup.id
output keyVaultName string = keyVault.name
output ciPrincipalId string = ciIdentity.properties.principalId
output ciClientId string = ciIdentity.properties.clientId
