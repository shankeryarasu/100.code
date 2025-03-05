//

param location string = 'eastus'
param storageAccountName string = 'toylaunch${uniqueString(resourceGroup().id)}'
param appServiceAppName string = 'toylauncha${uniqueString(resourceGroup().id)}'

@allowed([
  'nonprod'
  'prod'
])
param environmentType string
var storageAccountNameSkuname = (environmentType == 'prod') ? 'Standard_GRS' : 'Standard_LRS'
//var appserviceplanSkuName = (environmentType == 'prod') ? 'P1V2' : 'F1'

//var appserviceplanName = 'toylaunchappserviceplan'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
    sku: {
     name: storageAccountNameSkuname
       }
   kind: 'StorageV2'
   properties: {
         accessTier: 'Hot'    
 }
 }


module appservice 'Modules/appservice.bicep' = {
  name: 'appservice'
  params: {
    location: location
    appServiceAppName: appServiceAppName
    environmentType: environmentType
  }
}


output appServiceAppHostName string = appservice.outputs.appservicehostname
output storageAccountName string = storageAccount.name

//Deploy using below cmd
// az deployment group create --name main --template-file main.bicep --parameters environmentType=nonprod
// -------------------
// @description('the azure region into which the resources should be deployed')
// param location string 

// @secure()
// @description('sql server admin username')
// param sqlServerAdministratorLogin string

// @secure()
// @description('sql server admin password')
// param sqlServerAdministratorLoginPassword string  

// @description('sql server sku.')
// param sqlDatabaseSku object = {
//   name: 'Standard '
//   tier: 'Standard'  
// }

// var sqlServerName = 'teddy${uniqueString(resourceGroup().id)}'
// var sqlDatabaseName = 'TeddyBearDb'

// @description('the name of the env either prod or dev')
// @allowed([
//   'Development'
//   'Production'
// ])

// param environmentName string = 'Development'

// @description('name of the sku for the storage account')
// param auditstorageAccountSkuName string = 'Standard_L RS'

// var auditingEnabled = environmentName == 'Production'
// var auditStorageAccountName = take('bearaudit${location}${uniqueString(resourceGroup().id)}', 24)

// resource sqlServer 'Microsoft.Sql/servers@2021-05-01-preview' = {
//   name: sqlServerName
//   location: location
//   properties: {
//     administratorLogin: sqlServerAdministratorLogin
//     administratorLoginPassword: sqlServerAdministratorLoginPassword
//     version: '12.0'
//   }
// }

// resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
//   parent: sqlServer
//   name: sqlDatabaseName   
//   location: location
//   sku: sqlDatabaseSku
// }

// resource sqlServeraudit 'Microsoft.Sql/servers/auditingSettings@2024-05-01-preview' = if (auditingEnabled) {
//   parent: sqlServer
//   name: 'Default'
//   properties: {
//     state: 'Enabled'
//     storageEndpoint: environmentName == 'Production' ? auditStorageAccount.properties.primaryEndpoints.blob: ''
//     storageAccountAccessKey: environmentName = 'Production' ? (auditStorageAccount.listkeys().keys[0].value: ''
//   }
// }

// resource auditStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = if (auditingEnabled) {
//   name: auditStorageAccountName
//   location: location
//   sku: {
//     name: auditstorageAccountSkuName
//   }
//   kind: 'StorageV2'
//   properties: {
//     accessTier: 'Hot'
//   }
// }
