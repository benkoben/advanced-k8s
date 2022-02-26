@description('Specifies the name of the project. This name is reflected in resource group and sub-resources')
param projectName string

@description('Specifies the tags that should be applied to newly created resources')
param tags object

@description('Specifies the id of the virtual network used for private endpoints')
param vnetId string

@description('Specifies the name of the subnet used for the private endpoints')
param subnetName string

param enablePrivateDnsZone bool = false

var locationSuffix = 'weeu'
var env = 'dev'

module sacc './modules/storageAccount.bicep' = {
  name: 'StorageAccount'
  params: {
    storageAccountName: 'sacc${projectName}${locationSuffix}${env}001'
    skuName: 'Standard_LRS'
    vnetId: vnetId
    subnetName: subnetName
    blobPrivateEndpointName: 'pend-${projectName}-blob-to-vnt-mlcmn'
    filePrivateEndpointName: 'pend-${projectName}-file-to-vnt-mlcmn' 
    tags: tags
  }
}

module privateDns 'modules/privateDns.bicep' = if(enablePrivateDnsZone){
  name: 'privateDnsZoneCreationAndLink'
  params: {
    dnsConfig: sacc.outputs.dnsConfig
    privateLinksDnsZones: {
      'blob': {
        'id': '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
      }
      'file': {
        'id': '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net'
      }
    }
  }
}
