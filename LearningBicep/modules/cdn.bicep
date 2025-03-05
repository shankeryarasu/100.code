@description('the host name address of the origin server')
param originHostName string

@description('CDN profile name')
param ProfileName string = 'cdn-${uniqueString(resourceGroup().id)}'

@description('the name of the CDN endpoint')
param cdnEndpointName string = 'endpoint-${uniqueString(resourceGroup().id)}'

@description('Indicates whether the CDN endpoint required HTTPS connection.')
param httpsOnly bool = true

var originname = 'my-origin'

resource cdnprofile 'Microsoft.Cdn/profiles@2024-09-01' = {
  name: ProfileName
  location: 'global'
  sku: {
    name: 'Standard_Microsoft'
  }
}

resource endpoint 'Microsoft.Cdn/profiles/endpoints@2024-09-01' = {
  parent: cdnprofile
  name: cdnEndpointName
  location: 'global'
  properties: {
    originHostHeader: originHostName
    isHttpAllowed: !httpsOnly
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    contentTypesToCompress: [
      'text/plain'
      'text/html'
      'text/css'
      'application/x-javascript'
      'text/javascript'
    ]
    isCompressionEnabled: true
    origins: [
      {
        name: originname
        properties: {
          hostName: originHostName
        }
      }
    ]
  }
}

@description('the hostname of the cdn endpoint')
output EndpointHostName string = endpoint.properties.hostName
