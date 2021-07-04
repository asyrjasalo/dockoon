/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param law_name string
param tags object
param retention_in_days int = 30

/*
------------------------------------------------------------------------------
VARIABLES
------------------------------------------------------------------------------
*/

resource law 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: law_name
  location: resourceGroup().location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retention_in_days
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

/*
------------------------------------------------------------------------------
OUTPUTS
------------------------------------------------------------------------------
*/

output logAnalyticsWorkspaceId string = law.id
