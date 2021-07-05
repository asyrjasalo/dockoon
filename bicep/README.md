# Running on Azure Container Instances

The following are created in your Azure subscription:

- TLS certificates for HTTPS (automated renewal if not having one already)
- Azure Container Instances (in private networking mode, in virtual network)
- Storage Account hosting a file share used as the container volume
- Internet exposed API Management Gateway which logs to Log Analytics Workspace
- API Management API (HTTPS front) with the containerized app as the backend

## Setup

[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) is assumed present and used to install or upgrade 
[bicep](https://github.com/Azure/bicep):

    az bicep install
    az bicep upgrade

## Prerequisites

### Domain name

You must own a domain which is delegated to an existing public DNS zone in the same Azure subscription. Deployment will create DNS records (A) in the zone for
the Container Instance app (private IP) and API Management Gateway (public IP).

### Certificate

To use Let's Encrypt to get free TLS X.509 certificates for your domain(s),
and in addition to have them renewed automatically every 90 days, deploy
[keyvault-acmebot](https://github.com/shibayan/keyvault-acmebot) in the
same Azure subscription.

The deployment creates a separate resource group, including resources such as a
consumption tier Function App. Also a key vault is created where 
the certificates are uploaded after created or renewed.

Use `/add-certificate` to request a certificate. You can either create a
wildcard certificate (such as `*.yourdomain.dev`, recommended) or create a cert
including all the subdomains that API Management exposes (see `apim.bicep`).

## Deploy

Login to Azure:

    az login

Copy `test.env.example` to `test.env`, configure variables and export them:

    source test.env

Create a target resource group for the deployment:
    
    az group create \
        --name "$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-rg" \
        --location "$AZ_LOCATION" \
        --subscription "$AZ_SUBSCRIPTION_ID" \
        --tags app=$AZ_APP environment=$AZ_ENVIRONMENT owner=$AZ_OWNER

Deploy (everything except DNS and key vault changes) to this resource group:

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

Note 1) initially creating API Management service might take an hour and
2) the DNS and the key vault specific *deployments* are visible in their
own resource groups.

Add your client IP as allowed in the Storage Account's Networking settings and
upload `apis.json` to a File shared named `share` to get the container running.

Alternatively, you can configure the Docker start command in `aci.bicep`
if you rather load the API definitions over HTTPS.
