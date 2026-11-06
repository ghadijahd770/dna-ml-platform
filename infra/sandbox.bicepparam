// Sandbox settings for the DNA ML platform.
// Values marked CHANGE-ME must be filled in before the first deployment.
// Group object IDs and the alert email are read from environment variables, set by
// scripts/get-group-ids.sh (local) or GitHub repository variables (workflow).

using './main.bicep'

param location = 'southafricanorth'
param regionCode = 'san'
param env = 'sbx'
param team = 'dna'
param instance = '01'

// ── Tags and cost ─────────────────────────────────────────────────────────────
param owner = 'dna-platform'
param costCentre = 'CHANGE-ME'
param expires = '2027-02-28'
param alertEmail = readEnvironmentVariable('DNA_ALERT_EMAIL', 'CHANGE-ME@example.com')
param monthlyBudget = 500
param budgetStartDate = '2026-11-01'

// ── Access: Entra group object IDs ────────────────────────────────────────────
param groupIds = {
  platformAdmins: readEnvironmentVariable('DNA_GROUP_PLATFORM_ADMINS', '')
  dataEngineers: readEnvironmentVariable('DNA_GROUP_DATA_ENGINEERS', '')
  dataScientists: readEnvironmentVariable('DNA_GROUP_DATA_SCIENTISTS', '')
  mlEngineers: readEnvironmentVariable('DNA_GROUP_ML_ENGINEERS', '')
  genaiDevelopers: readEnvironmentVariable('DNA_GROUP_GENAI_DEVELOPERS', '')
  viewers: readEnvironmentVariable('DNA_GROUP_VIEWERS', '')
}

param githubRepo = 'ghadijahd770/dna-ml-platform'
param githubEnvironment = 'sandbox'
param grantCiSubscriptionAccess = true

// ── Azure ML ──────────────────────────────────────────────────────────────────
param cpuClusterVmSize = 'Standard_DS3_v2'
param cpuClusterMaxNodes = 2
param deployGpuCluster = false // turn on only after GPU quota is approved
param gpuClusterVmSize = 'Standard_NC4as_T4_v3'
param gpuClusterMaxNodes = 1
param disableStorageSharedKey = false // see docs/network-decision.md before turning on

// ── Foundry ───────────────────────────────────────────────────────────────────
param deployFoundry = true

// Approved models only. Empty until security agrees the list and you've checked
// the model is offered in the region.
// Data residency: 'GlobalStandard' may process prompts in any Azure region;
// 'Standard' keeps processing in the resource's region. Agree the SKU with security.
// Example entry:
//   {
//     name: 'gpt-4o-mini'
//     model: 'gpt-4o-mini'
//     version: '2024-07-18'
//     format: 'OpenAI'
//     sku: 'GlobalStandard'
//     capacity: 10
//   }
param foundryModelDeployments = []
