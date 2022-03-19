@secure()
@description('Specifies a secure string used as password new local admin user')
param adminPassword string

@description('Specifies the name of the local admin user')
param adminUsername string

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2_v3'

@description('location for all resources')
param location string = resourceGroup().location

@description('Specifies the name of the virtual machine')
param vmName string

@description('Specifies the subnet that the virtual machine should be connected to')
param subnetName string

@description('Specift the virtual network id used for network interface')
param vnetId string

@description('The tags that should be applied on virtual machine resources')
param tags object

param imageReference object

param publicKeys array

@description('(Required) speficies the keyvault used to save local admin credentials')
param keyvaultName string

// Two different names are generated because of the conditional resources.
// Without this we get a duplicate resource error

var subnetRef = '${vnetId}/subnets/${subnetName}'

// --- Public IP VM ---
var pipNicName = '${vmName}-nic-${substring(uniqueString(vmName), 0, 5)}'

resource pip 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'pip-${vmName}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: '${vmName}-pub'
    }
  }
}

resource nInter 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: pipNicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource virtualMachineWithPublicIp 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: substring(vmName,0,14) // No more than 15 chars are allowed for this field
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        ssh: {
          publicKeys: publicKeys
        }
      }
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 1024
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nInter.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource automaticShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${virtualMachineWithPublicIp.name}'
  location: location
  tags: tags
  properties: {
    dailyRecurrence: {
      time: '2300'
    }
    status: 'Enabled'
    targetResourceId: virtualMachineWithPublicIp.id
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'W. Europe Standard Time'
  }
}

resource keyvaultadminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyvaultName}/${virtualMachineWithPublicIp.name}-AdminPassword'
  properties: {
    value: adminPassword
  }
}

resource keyvaultadminUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyvaultName}/${virtualMachineWithPublicIp.name}-AdminUsername'
  properties: {
    value: adminUsername
  }
}

output hostname string = pip.properties.dnsSettings.fqdn
