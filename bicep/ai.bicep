/*
------------------------------------------------------------------------------
PARAMETERS
------------------------------------------------------------------------------
*/

param ai_name string
param law_id string
param tags object

/*
------------------------------------------------------------------------------
RESOURCES
------------------------------------------------------------------------------
*/

resource ai 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: ai_name
  location: resourceGroup().location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: law_id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

/*
------------------------------------------------------------------------------
OUTPUTS
------------------------------------------------------------------------------
*/
