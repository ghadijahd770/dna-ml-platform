// Shared parameter types for the DNA ML platform templates.

@export()
@description('Object IDs of the Entra security groups. Leave a value empty to skip that group\'s role assignments.')
type groupIdsType = {
  @description('sg-dna-platform-admins')
  platformAdmins: string
  @description('sg-dna-data-engineers')
  dataEngineers: string
  @description('sg-dna-data-scientists')
  dataScientists: string
  @description('sg-dna-ml-engineers')
  mlEngineers: string
  @description('sg-dna-genai-developers')
  genaiDevelopers: string
  @description('sg-dna-viewers')
  viewers: string
}

@export()
@description('One approved Foundry model deployment.')
type modelDeploymentType = {
  @description('Deployment name apps will call, e.g. gpt-4o-mini')
  name: string
  @description('Model name in the Foundry catalogue')
  model: string
  @description('Model version')
  version: string
  @description('Model format, e.g. OpenAI')
  format: string
  @description('Deployment SKU, e.g. GlobalStandard or Standard')
  sku: string
  @description('Capacity in thousands of tokens per minute')
  capacity: int
}
