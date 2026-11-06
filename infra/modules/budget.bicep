// Monthly budget on one resource group, alerting the platform action group at 50 %, 80 % and 100 %.

param budgetName string
param amount int
@description('First day of a month, yyyy-MM-01.')
param startDate string
param actionGroupId string

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      actual50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        thresholdType: 'Actual'
        contactGroups: [
          actionGroupId
        ]
      }
      actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactGroups: [
          actionGroupId
        ]
      }
      actual100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Actual'
        contactGroups: [
          actionGroupId
        ]
      }
    }
  }
}
