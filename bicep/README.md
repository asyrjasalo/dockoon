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

### Domain name

You must own an domain which is delegated to a public DNS zone present in the same Azure subscription. This allows deployment to create the DNS records for
Azure Container Instances and the API Management in the zone.

### SSL certificate

Deploy [keyvault-acmebot](https://github.com/shibayan/keyvault-acmebot) in the
same Azure subscription. The deployment will create a separate resource group.

The deployment creates an consumption tier Function App for automatically
and periodically renewing certificates. It also creates a key vault in which
the certificates are created and updated.

Use the web GUI to issue a new wildcard certificate. Note the certificate name,
as you need to configure it further below (along with the key vault name and
the key vault resource group name).

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
        -p prefix="$AZ_PREFIX" \
        -p app="$AZ_APP" \
        -p environment="$AZ_ENVIRONMENT" \
        -p owner="devops@$AZ_DNS_ZONE_NAME" \
        -p dns_zone_name="$AZ_DNS_ZONE_NAME" \
        -p dns_zone_rg_name="$AZ_DNS_ZONE_RG_NAME" \
        -p key_vault_name="$AZ_KEY_VAULT_NAME" \
        -p key_vault_rg_name="$AZ_KEY_VAULT_RG_NAME" \
        -p key_vault_cert_name="$AZ_KEY_VAULT_CERT_NAME"

Note that the DNS and the key vault related *deployments* are created and thus
visible in their own resource groups.

## Usage

Add your client IP as allowed in the Storage Account's Networking settings and
upload `apis.json` to a File shared named `share` to get the container running.

Alternatively, you can configure the Docker start command in `aci.bicep`
if you rather load the API definitions over HTTPS.

Finally, create a new API in API Management with the backend URL created in the DNS zone for the Azure Container Instances (which resolves to a private IP).

As the API Management itslef is deployed in the public network (external mode) 
so make sure you require subscription key for the APIs hosted in API Management.
