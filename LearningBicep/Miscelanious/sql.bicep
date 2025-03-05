@allowed([
  'Development'
  'Production'
])
param environmentType string
param location string = resourceGroup().location
param auditStorageAccouontName string = 'bareaudit${uniqueString(resourceGroup().id)}' 

var auditingEnabled = environmentType == 'Production' 
var storageAccountSku =  'Standard_GRS' 

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = if(auditingEnabled{
  name: auditStorageAccouontName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource auditingsettings 'Microsoft.Sql/servers/auditingSettings@2024-05-01-preview' = if (auditingEnabled) {
  parent: server
  name: default
  properties:{
    state: 'Enabled'
    storageEndpoint: environmentType == 'Production' ? auditStorageAccouontName.properties.primaryEndpoints.blob :''
    storageAccountAccessKey: environmentType == 'Production' ? listKeys(auditStorageAccouontName.id, '2021-06-01').keys[0].value :''
  }
}


