@secure()
param adminPassword string
param location string = resourceGroup().location
param vaultName string =  'k8s-keyv-weeu-dev-001'
param vnetName string
param vnetRg string
param env string =  'dev'

var enableVmPubIp = true
var adminUsername = 'kooijman'
var subnetName = 'kuberneteslab'
var tags = {}

var keyPath = '../../keys/id_rsa.pub'

resource vault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing =  {
  name: vaultName
}

module vmPublic './modules/linuxVirtualmachinePublic.bicep' = if(enableVmPubIp == true) {
  scope: resourceGroup()
  name: 'publicLinuxVirtualMachine'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: 'Standard_DS3_v2'
    location: location
    vmName: 'gitlab-vm-weeu-${env}-001'
    imageReference: {
      offer: 'UbuntuServer'
      publisher: 'Canonical'
      sku: '18.04-LTS'
      version: 'latest'
    }
      publicKeys: [
        {
          keyData: loadTextContent(keyPath, 'utf-8')
          path: '/home/${adminUsername}/.ssh/authorized_keys'
        }
      ]
    subnetName: subnetName
    vnetId: resourceId(vnetRg, 'Microsoft.Network/VirtualNetworks', vnetName)
    tags: tags
    keyvaultName: vault.name
  }
}
