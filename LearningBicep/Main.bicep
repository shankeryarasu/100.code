@description('the azure region into which the resources should be deployed')
param location string = 'westus'

@description('app service app name')  
param appServiceAppName string = 'toy-${uniqueString(resourceGroup().id)}'

@description('the name of the app service plan sku name')
param appServicePlanSkuName string = 'F1'

@description('indicate whether a CDN should be deployed')
param deployCDN bool = true

var appServicePlanName = 'toy-product-launch-plan'

module app 'Modules/app.bicep' = {
  name: 'toy-launch-app'
  params: {
    location: location
    appServiceAppName: appServiceAppName
    appServicePlanName: appServicePlanName
    appServicePlanSkuName: appServicePlanSkuName
  }
}
//C:\GitRepos\LearningBicep\Modules\cdn.bicep
module cdn 'Modules/cdn.bicep' = if(deployCDN) {
  name: 'cdn'
  params: {
    httpsOnly: true
    originHostName: app.outputs.appservicehostname
  }
}



@description('the hostname to use to access the website')
output websiteHostName string = deployCDN ? cdn.outputs.EndpointHostName : app.outputs.appservicehostname
