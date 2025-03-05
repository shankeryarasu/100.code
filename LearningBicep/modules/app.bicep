//param location string
//param appServiceAppName string

// @allowed([
//   'nonprod'
//   'prod'
// ])
// param environmentType string

// var appServicePlanName = 'toy-product-launch-plan'
// var appservicePlanSkuName = (environmentType == 'prod')? 'P1V2' : 'F1'


@description('the azure region into which the resources should be deployed')
param location string 

@description('app service app name')
param appServiceAppName string
@description('the name of the app service plan')
param appServicePlanName string
@description('the sku of the app service plan')
param appServicePlanSkuName string  

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
    tier: 'Free'
  }
  properties: {
    reserved: true
  }
}

resource appServiceApp 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
} 

@description('the hostname of the app service')
output appservicehostname string = appServiceApp.properties.defaultHostName

