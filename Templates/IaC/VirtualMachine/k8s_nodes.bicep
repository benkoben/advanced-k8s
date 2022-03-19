@secure()
param adminPassword string
param location string = resourceGroup().location
param vaultName string =  'k8s-keyv-weeu-dev-001'
param env string = 'dev'
param vnetName string
param vnetRg string

// variables start here
var enableVmPubIp = true

var adminUsername = 'kooijman'
var subnetName = 'kuberneteslab'
var keyPath = '../../keys/id_rsa.pub'

module masterPublic './modules/linuxVirtualmachinePublic.bicep' = if(enableVmPubIp == true) {
  scope: resourceGroup()
  name: 'masterNodePublicIp'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: 'Standard_B1ms'
    location: location
    vmName: 'node01-vm-weeu-${env}-001'
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
    tags: {
      node_role: 'Master'
    }
    keyvaultName: vaultName
  }
}

module worker01Public './modules/linuxVirtualmachinePublic.bicep' = if(enableVmPubIp == true) {
  scope: resourceGroup()
  name: 'workerNode01PublicIP'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: 'Standard_B1ms'
    location: location
    vmName: 'node02-vm-weeu-${env}-001'
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
    tags: {
      node_role: 'Worker'
    }
    keyvaultName: vaultName
  }
}

module worker02Public './modules/linuxVirtualmachinePublic.bicep' = if(enableVmPubIp == true) {
  scope: resourceGroup()
  name: 'workerNode02PublicIP'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: 'Standard_B1ms'
    location: location
    vmName: 'node03-vm-weeu-${env}-001'
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
    tags: {
      node_role: 'Worker'
    }
    keyvaultName: vaultName
  }
}
