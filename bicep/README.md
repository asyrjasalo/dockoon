# Running on Azure Container Instances

The following are created:
- Azure Container Instances (in private networking mode)
- Storage Account hosting a file share to use as a container volume
- API Management (with public IP) ingesting logs to Log Analytics Workspace

## Setup

[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) is required.

Use Azure CLI to install or upgrade [bicep](https://github.com/Azure/bicep):

    az bicep install
    az bicep upgrade

## Prerequisites

### Certificates

Deploy [keyvault-acmebot](https://github.com/shibayan/keyvault-acmebot)
in the same Azure subscription (but in a separate resource group).

The deployment creates a Function App automatically issues/renews certificates and creates a key vault in which the certificates are stored.

Use the function app GUI to issue wildcard certificates (left as an exercise).

### DNS zone

An existing DNS zone must be present for the deployment to create DNS records 
for Azure Container Instances and API Management.

## Deploy

Login to Azure:

    az login

Copy `test.env.example` to `test.env`, configure variables and source the file:

    source test.env

Create a target resource group for the deployment:
    
    az group create \
        --name "$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-rg" \
        --location "$AZ_LOCATION" \
        --subscription "$AZ_SUBSCRIPTION_ID" \
        --tags app=$AZ_APP environment=$AZ_ENVIRONMENT owner=$AZ_OWNER

Deploy to the resource group:

    az deployment group create \
        --resource-group "$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-rg" \
        --template-file ./main.bicep \
        --parameters prefix="$AZ_PREFIX" \
        --parameters app="$AZ_APP" \
        --parameters environment="$AZ_ENVIRONMENT" \
        --parameters owner="devops@$AZ_DNS_ZONE_NAME" \
        --parameters dns_zone_name="$AZ_DNS_ZONE_NAME" \
        --parameters dns_zone_rg_name="$AZ_DNS_ZONE_RG_NAME" \
        --parameters key_vault_name="$AZ_KEY_VAULT_NAME" \
        --parameters key_vault_rg_name="$AZ_KEY_VAULT_RG_NAME"

Note that the DNS zone and the key vault related *deployments* are created in their own respective resource groups.

## Usage

Add your client IP as allowed in the Storage Account's Networking settings and
upload `apis.json` to File shared named `share` to get the container running.

Alternatively, configure the Docker start command in `aci.bicep` if you rather
load the API definitions over HTTPS.

Finally, create a new API in API Management with the backend URL created in the DNS zone for the Azure Container Instances (resolving to a private IP).

As the API Management itslef is deployed in the public network (external mode) 
make sure you require subscription key for the APIs in API Management.
