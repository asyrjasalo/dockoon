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
VARIABLES
------------------------------------------------------------------------------
*/

var ai_kind = 'web'

/*
------------------------------------------------------------------------------
RESOURCES
------------------------------------------------------------------------------
*/

resource ai 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: ai_name
  location: resourceGroup().location
  tags: tags
  kind: ai_kind
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
