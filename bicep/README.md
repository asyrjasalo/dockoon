# Running on Azure Container Instances behind API Management

The instructions will create the following in your Azure subscription:

- TLS certificates for HTTPS (automated renewal if not having one already)
- Azure Container Instances (in private networking mode, in virtual network)
- Storage Account for hosting API specs and to use as a container volume mount
- Internet exposed API Management with AppInsights and Log Analytics Workspace
- API Management API (HTTPS front) with the containerized app as the backend

## Local setup

[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) is assumed present and used to install or upgrade 
[bicep](https://github.com/Azure/bicep):

    az bicep install
    az bicep upgrade

## Prerequisites

### Domain name

You must own a domain which is delegated to an existing public DNS zone in the same Azure subscription. Deployment will create DNS records in the zone for
the Container Instance app (A to private IP) and API Management Gateway (CNAME).

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

## Deploy to Azure

Copy `test.env.example` to `test.env`, configure variables and export them:

    source test.env

Create a target resource group for the deployment:
    
    az group create \
        --name "$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-rg" \
        --location "$AZ_LOCATION" \
        --subscription "$AZ_SUBSCRIPTION_ID" \
        --tags app=$AZ_APP environment=$AZ_ENVIRONMENT owner=$AZ_OWNER

Note that creating API Management service might take an hour, and that DNS and
key vault specific *deployments* will be visible in their own resource groups.

Deploy (everything except DNS and key vault changes) to the resource group:

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

Upload `apis.json` and `openapi.json` to the Storage Account container `apis`
to get the container status from 'waiting' to 'running' and also to get
the API deployment to succeed.

## API management

This chapter briefly summarizes some good operational practices (ApiOps).

### Developer portal

DNS records for API Gateway, Developer Portal (new version) and Management API 
are created in the DNS zone and set as custom domains in APIM by deployment.

The developer portal (as well as management API) must be explicitly published
in the API Management. To publish Developer Portal via Azure portal,
browser to API Management -> Portal Overview -> Publish.

### API key

The API is created in the product `app_name` (which is also created). An API
Management default group named 'Developers' is assigned to the product.

To get a subscription key for the API, sign up via your API Management
developer portal. Portal signed up user is automatically placed in the group
'Developers', thus granting access (and a subscription key) to the product.

## API development

Redeploy API in APIM based on the latest OpenAPI specification available:

    az deployment group create \
        --resource-group "$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-rg" \
        --template-file ./api.bicep \
        -p apim_name="$AZ_PREFIX-$AZ_ENVIRONMENT-${AZ_APP}-apim" \
        -p app_name="$AZ_APP" \
        -p api_backend_url="http://$AZ_APP-$AZ_ENVIRONMENT.$AZ_DNS_ZONE_NAME:8080" \
        -p api_spec="https://${AZ_PREFIX}${AZ_ENVIRONMENT}${AZ_APP}sa.blob.core.windows.net/apis/openapi.json"

### Parameters

The API display name is taken from the API spec and the product name is taken
from `app_name`. You can optionally configure parameters `app_description` and 
`app_terms` for the product, and `api_description` for the API.

If you want to switch the latest API revision live manually, add parameter
`api_set_current=false`. By default, **the new revision is set as current**, 
which may not be wanted in production environment. Note that a new revision is 
created in API Management only if the new API specification introduces changes.

If you want to require **no authentication** for the particular API deployed, 
add `api_require_auth=false`. Authentication is still required on the product 
level for the other APIs that are possibly assigned in the product.

If you want to require **no approval from Administrators** when new users
subscribe to the product, add `app_require_admin_approval=false`.

OpenAPI (3.x), Swagger (2.x) and WSDL specification formats can be imported by
API Management. If are deploying a SOAP API instead of REST, add 
`api_type=soap` and use `api_format=wsdl-link` with `api_spec` URL to the XML.

It is possible to set `api_format` to `openapi-json`, `swagger-json` or `wsdl`
if you want to read `api_spec` content directly as a parameter. This may or
may not work well, depending on your shell's limitations.
