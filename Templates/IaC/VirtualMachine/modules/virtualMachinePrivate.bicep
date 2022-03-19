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

@description('(Required) speficies the keyvault used to save local admin credentials')
param keyvaultName string

param imageReference object

var nicName = '${vmName}-nic-${substring(uniqueString(vmName), 0, 5)}'
var subnetRef = '${vnetId}/subnets/${subnetName}'



resource nInter 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = {
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
  name: 'shutdown-computevm-${virtualMachine.name}'
  location: location
  tags: tags
  properties: {
    dailyRecurrence: {
      time: '2300'
    }
    status: 'Enabled'
    targetResourceId: virtualMachine.id
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'W. Europe Standard Time'
  }
}

resource keyvaultadminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyvaultName}/virtualMachineAdminPassword'
  properties: {
    value: adminPassword
  }
}

resource keyvaultadminUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyvaultName}/virtualMachineAdminUsername'
  properties: {
    value: adminUsername
  }
}
