/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param aci_name string
param aci_container_image string
param aci_container_command array
param aci_container_envvars array
param aci_container_port int
param aci_container_restart_policy string
param aci_vcpu_count int
param aci_memory_gbs string
param aci_nic_name string
param aci_subnet_id string
param sa_name string
param tags object

/*
------------------------------------------------------------------------------
EXISTING_RESOURCES
------------------------------------------------------------------------------
*/

resource sa 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: sa_name
}

/*
------------------------------------------------------------------------------
RESOURCES
------------------------------------------------------------------------------
*/

resource netp 'Microsoft.Network/networkProfiles@2020-11-01' = {
  name: 'netp'
  location: resourceGroup().location
  tags: tags
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: aci_nic_name
        properties: {
          ipConfigurations: [
            {
              name: 'private'
              properties: {
                subnet: {
                  id: aci_subnet_id
                }
              }
            }
          ]
        }
      }
    ]
  }
}

resource aci 'Microsoft.ContainerInstance/containerGroups@2021-03-01' = {
  name: aci_name
  location: resourceGroup().location
  tags: tags
  properties: {
    sku: 'Standard'
    containers: [
      {
        name: 'app'
        properties: {
          image: aci_container_image
          command: aci_container_command
          ports: [
            {
              protocol: 'TCP'
              port: aci_container_port
            }
          ]
          environmentVariables: aci_container_envvars
          resources: {
            requests: {
              cpu: aci_vcpu_count
              memoryInGB: aci_memory_gbs
            }
          }
          volumeMounts: [
            {
              name: 'share'
              mountPath: '/share'
              readOnly: true
            }
          ]
        }
      }
    ]
    initContainers: []
    restartPolicy: aci_container_restart_policy
    ipAddress: {
      ports: [
        {
          protocol: 'TCP'
          port: aci_container_port
        }
      ]
      type: 'Private'
    }
    osType: 'Linux'
    volumes: [
      {
        name: 'share'
        azureFile: {
          shareName: 'share'
          readOnly: true
          storageAccountName: sa.name
          storageAccountKey: listKeys(sa.id, '2019-06-01').keys[0].value
        }
      }
    ]
    networkProfile: {
      id: netp.id
    }
  }
}

/*
------------------------------------------------------------------------------
OUTPUTS
------------------------------------------------------------------------------
*/

output aciId string = aci.id
output aciIpAddress string = aci.properties.ipAddress.ip
