/*
 * Premium Azure function app.
 */

@description('App name')
param appName string

@description('App short name')
@maxLength(15)
param appNameShort string

@description('Location for all resources')
param location string

@description('The environment the resources are being deployed to.')
param env string

@description('App Service Plan ID')
param servicePlanId string

@description('Virtual network subnet ID')
param subnetId string

@description('Private Endpoint subnet ID')
param privateEndpointSubnetId string

@description('Private DNS Zone ID')
param privateDnsZoneId string

@description('Name of the key vault')
param vaultName string

@description('Optional override for storage account name')
param storageNameOverride string = ''

@description('Insights name')
param insightsName string

@allowed(['Production', 'NonProduction'])
param environmentType string = env == 'prod' ? 'Production' : 'NonProduction'

@description('.NET Framework version')
param netFrameworkVersion string = 'v6.0'

@description('Number of minimum instance count for a site. This setting only applies to the Elastic Plans')
param minElasticInstanceCount int = env == 'prod' ? 3 : 1

// Private Endpoint for Storage

@description('Blob Private DNS Zone ID')
param saBlobPrivateDnsZoneId string

var environmentConfigurationMap = {
  Production: {
    storageAccount: {
      sku: {
        name: 'Standard_ZRS'
      }
    }
  },
  NonProduction: {
    storageAccount: {
      sku: {
        name: 'Standard_LRS'
      }
    }
  }
};

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-06-01' = {
  name: empty(storageNameOverride) ? 'ctgsafa${appNameShort}${env}' : storageNameOverride
  location: location

  sku: {
    name: environmentConfigurationMap[environmentType].storageAccount.sku.name
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: subnetId
        }
      ]
    }
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: insightsName
}

resource vault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: vaultName
  scope: resourceGroup()
}
#----------------------------
resource appServicePlan 'Microsoft.Web/serverfarms@2022-06-01' = {
  name: 'asp-${appName}-${env}'
  location: location
  kind: 'functionapp'
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
    size: 'EP1'
    family: 'EP'
    capacity: 1
  }
}
#-----------------------
resource app 'Microsoft.Web/sites@2022-06-01' = {
  name: 'ctg-azf-${appName}-${env}'
  kind: 'functionapp'
  location: location
  tags: {}

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    virtualNetworkSubnetId: subnetId

    siteConfig: {
      functionsRuntimeScaleMonitoringEnabled: false
      alwaysOn: true
      netFrameworkVersion: netFrameworkVersion
      use32BitWorkerProcess: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      vnetRouteAllEnabled: true
      minimumElasticInstanceCount: minElasticInstanceCount

      appSettings: [
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
      ]
    }
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: '${app.name}-logs'
  scope: app
  properties: {
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
        }
      }
    ]
    workspaceId: insights.properties.WorkspaceId
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-06-01' = {
  name: 'ctg-pe-azf-${appName}-${env}'
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'privateLink${uniqueString(resourceGroup().name)}'
        properties: {
          privateLinkServiceId: app.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-06-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privateLinkwebsite${uniqueString(resourceGroup().name)}'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

resource storagePrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2022-06-01' = {
  name: 'ctg-pe-safa-blob-${appNameShort}-${env}'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'privateLinkwebsite${uniqueString(resourceGroup().name)}'
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storageAccount.id
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnetId
    }
  }
}

resource blobPrivateEndpointDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-06-01' = {
  parent: storagePrivateEndpointBlob
  name: 'default'
  properties:{
    privateDnsZoneConfigs: [
      {
        name: 'privateLinkwebsite${uniqueString(resourceGroup().name)}'
        properties:{
          privateDnsZoneId: saBlobPrivateDnsZoneId
        }
      }
    ]
  }
}

var roleDefinitionIds = {
  KeyVaultSecretsUser: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
}

resource kvlogicAppPermissions 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(app.id, roleDefinitionIds.KeyVaultSecretsUser)
  scope: vault
  properties: {
    principalId: app.identity.principalId
    principalType: 'ServicePrincipal'
    #disable-next-line use-resource-id-functions
    roleDefinitionId: roleDefinitionIds.KeyVaultSecretsUser
  }
}

resource appSettingsCurrent 'Microsoft.Web/sites/config@2022-06-01' existing = {
  name: 'appsettings'
  parent: app
}

output principalId string = app.identity.principalId
output appName string = app.name
output storageName string = storageAccount.name
output appSettings object = appSettingsCurrent.list().properties
