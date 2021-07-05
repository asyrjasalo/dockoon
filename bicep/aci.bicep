/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param aci_name string
param aci_nic_name string
param aci_subnet_id string
param sa_name string
param tags object

param aci_container_memory string = '1.5'
param aci_container_vcpu int = 1
param aci_container_image string = 'asyrjasalo/mockoon:alpine'
param aci_container_restart_policy string = 'Always'
param aci_container_port int = 8080
param aci_container_envvars array = [
  {
    name: 'NODE_ENV'
    value: 'production'
  }
]
param aci_container_command array = [
  'sh'
  'runner.sh'
  'start'
  '--data'
  'https://${sa_name}.blob.core.windows.net/apis/apis.json'
  '--index'
  '0'
]

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
              memoryInGB: aci_container_memory
              cpu: aci_container_vcpu
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
          storageAccountName: sa_name
          storageAccountKey: listKeys(sa.id, '2019-06-01').keys[0].value
        }
      }
    ]
    networkProfile: {
      id: netp.id
    }
  }
  dependsOn: [
    sa
    netp
  ]
}

/*
------------------------------------------------------------------------------
OUTPUTS
------------------------------------------------------------------------------
*/

output aciId string = aci.id
output aciIpAddress string = aci.properties.ipAddress.ip
