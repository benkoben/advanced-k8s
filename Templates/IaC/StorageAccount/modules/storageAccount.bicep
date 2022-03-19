@description('Specifies the name of the new storage account')
param storageAccountName string

// Private endpoints
@description('Specifies name of the blob private endpoint')
param blobPrivateEndpointName string = 'none'

@description('Specifies the name of the file service private endpoint')
param filePrivateEndpointName string = 'none'

@description('Specifies the name of the storage account SKU')
param skuName string

@description('Specifies the id of the virtual network used for private endpoints')
param vnetId string

@description('Specifies the id of the subnet used for the private endpoints')
param subnetName string

@description('Specifies the tags that should be applied to the storage acocunt resources')
param tags object

var location = resourceGroup().location
var subnetRef = '${vnetId}/subnets/${subnetName}'
var groupIds = [
  {
    name: blobPrivateEndpointName
    gid: 'blob'
  }
  {
    name: filePrivateEndpointName
    gid: 'file'
  }
]

resource sacc 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  tags: tags
  location: location
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
}

resource pendSacc 'Microsoft.Network/privateEndpoints@2020-07-01' = [for obj in groupIds: {
  name: obj.name
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetRef
      name: subnetName
    }
    privateLinkServiceConnections: [
      {
        id: 'string'
        properties: {
          privateLinkServiceId: sacc.id
          groupIds: [
            obj.gid
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Compliance with network design'
          }
        }
        name: 'string'
      }
    ]
  }
}]

output storageAccountId string = sacc.id
output dnsConfig array = [
  {
    name: pendSacc[0].name
    type: 'blob'
  }
  {
    name: pendSacc[1].name
    type: 'file'
  }
]
