var enableVmPubIp = true
var env = 'dev'
var adminUsername = 'epirocadmin'
var adminPassword = '2RDvqT3f%%FdEXvRsvxS4qwFxXE%sv'
var location = 'westeurope'
var subnetName = 'kuberneteslab'
var vnetId = '/subscriptions/c386a05e-f364-4259-b587-5596787d235d/resourceGroups/ml-enterprise-test-rg/providers/Microsoft.Network/virtualNetworks/vnt-mlcmn-weeu-test-001'

var tags = {}

var keyPath = 'keys/id_rsa.pub'

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
    vnetId: resourceId('ben-dev-shared-network', 'Microsoft.Network/VirtualNetworks', 'ben-shared-vnet-spoke01-d')
    tags: tags
    keyvaultName: 'k8s-keyv-weeu-dev-001'
  }
}
