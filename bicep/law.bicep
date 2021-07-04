/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param law_name string
param tags object

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
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
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
