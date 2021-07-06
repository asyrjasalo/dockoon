# Running on Azure Container Instances and API Management

We will create the following in your Azure subscription:

- Azure Container Instance for the app (in private mode/in a virtual network)
- TLS certificates for HTTPS with automated renewal to a key vault
- Public API Management service with Portal, AppInsights and Log Analytics
- Storage Account for API specs and a share to use as a container volume mount
- Authenticated HTTPS API from an OpenAPI spec, container app as the backend

Principles:

- PaaS over virtual machines, Kubernetes, ingresses and API gateway software
- Use the cheapest option for running container workloads in a private network
- On Azure, target full ARM compatibility without actually writing any JSON
- Deployments ought not to have state management (e.g. Terraform and Pulumi)
- Pure and simple env vars over `azuredeploy.parameters.json` and configs
- Deploying a single API to APIM ought to be less than 100 lines of code

## Prerequisites

### Domain name

You must own a domain which is delegated to an existing public DNS zone in the same Azure subscription. Deployment will create DNS records in the zone for
the Container Instance app (A record) and API Management endpoints (3 CNAMEs).

### Certificate

To use Let's Encrypt to get free TLS X.509 certificates for your domain(s),
and in addition to have them renewed automatically every 90 days, deploy
[keyvault-acmebot](https://github.com/shibayan/keyvault-acmebot) in the
same Azure subscription.

The deployment creates a resource group, a consumption tier Function App and also a key vault where the certificates are uploaded after created or renewed.

Proceed according to the steps in
[getting started](https://github.com/shibayan/keyvault-acmebot#getting-started)
and finally use `/add-certificate` endpoint (web UI) to request a certificate.
You can either create a wildcard certificate (such as `*.yourdomain.dev`,
which is recommended here) or create a certificate including all the three 
subdomains that API Management exposes (see `apim.bicep` for them).

After successful, the vault will have the certificate. Note the certificate
name, key vault name and key vault resource group name as you need them below.

## Setup

[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) is assumed present to install or upgrade 
[bicep](https://github.com/Azure/bicep):

    az bicep install
    az bicep upgrade

## Deploy

Copy `prod.env.example` to `prod.env`, configure variables and export them:

    set -a; source prod.env; set +a

Create a target resource group:
    
    az group create \
        --name "$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-rg" \
        --location "$AZ_LOCATION" \
        --subscription "$AZ_SUBSCRIPTION_ID" \
        --tags app=$AZ_APP environment=$AZ_ENVIRONMENT owner=$AZ_OWNER

Create deployment in the resource group:

    az deployment group create \
        --resource-group "$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-rg" \
        --template-file main.bicep \
        -p prefix="$AZ_PREFIX" \
        -p environment="$AZ_ENVIRONMENT" \
        -p app="$AZ_APP" \
        -p owner="$AZ_OWNER" \
        -p dns_zone_name="$AZ_DNS_ZONE_NAME" \
        -p dns_zone_rg_name="$AZ_DNS_ZONE_RG_NAME" \
        -p key_vault_name="$AZ_KEY_VAULT_NAME" \
        -p key_vault_rg_name="$AZ_KEY_VAULT_RG_NAME" \
        -p key_vault_cert_name="$AZ_KEY_VAULT_CERT_NAME"

Note that creating a new API Management service might take half an hour.
Meanwhile, upload `apis.json` and `openapi.json` to the Storage Account:

    az storage file upload \
        --account-name "${AZ_PREFIX}${AZ_ENVIRONMENT}${AZ_APP}sa" \
        --share-name share \
        --source ../apis.json

    az storage blob upload \
        --account-name "${AZ_PREFIX}${AZ_ENVIRONMENT}${AZ_APP}sa" \
        --container-name apis \
        --name openapi.json \
        --file ../openapi.json

Note that the DNS and key vault specific *deployments* (= bicep modules)
are created in their respective resource groups and thus are visible there.

To run the above steps with a single command:

    ./deploy prod.env ../apis.json ../openapi.json

## API management

This chapter briefly summarizes some good operational practices.

### Portal

DNS records for API Gateway, Developer Portal (new version) and Management API 
are created in the DNS zone and set as custom domains in APIM by deployment.

The developer portal (as well as management API) must be explicitly published
in the API Management. To publish Developer Portal via Azure portal,
browser to API Management -> Portal Overview -> Publish.

### Registration

The API is created in the product `app_name` (which is also created). An API
Management default group named 'Developers' is assigned to the product.

To get a subscription key for the API, sign up via your API Management
developer portal. Portal signed up user is automatically placed in the group
'Developers', thus granting access (and a subscription key) to the product.

### Logging

100% of requests are logged into the Log Analytics Workspace regardless if
particular API has logging enabled or not. Similarly Application Insight 
metrics are stored in the workspace. You may adjust `retention_in_days`.

## API development

Redeploy API in APIM based on the latest OpenAPI specification available:

    az deployment group create \
        --resource-group "$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-rg" \
        --template-file api.bicep \
        -p apim_name="$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-apim" \
        -p app_name="$AZ_APP" \
        -p api_backend_url="http://$AZ_APP-$AZ_ENVIRONMENT.$AZ_DNS_ZONE_NAME:8080" \
        -p api_spec="https://${AZ_PREFIX}${AZ_ENVIRONMENT}${AZ_APP}sa.blob.core.windows.net/apis/openapi.json"

### Revisions

The API display name is taken from the API spec and the product name is taken
from `app_name`. You can optionally configure parameters `app_description` and 
`app_terms` for the product, and `api_description` for the API.

If you want to switch the latest API revision live manually, add parameter
`api_set_current=false`. By default, **the new revision is set as current**, 
which may not be wanted in production environment. Note that a new revision is 
created in API Management only if the new API specification introduces changes.

### Subscription

If you want to require **no authentication** for the particular API deployed, 
add `api_require_auth=false`. Authentication is still required on the product 
level for the other APIs that are possibly assigned in the product.

If you want to require **no approval from Administrators** when new users
subscribe to the product, add `app_require_admin_approval=false`.

### Spec and policy

OpenAPI (3.x), Swagger (2.x) and WSDL specification formats can be imported by
API Management. If are deploying a SOAP API instead of REST, add 
`api_type=soap` and use `api_format=wsdl-link` with `api_spec` URL to the XML.

If you want to read `api_spec` content directly as a parameter,
set `api_format` to `openapi-json`, `swagger-json` or `wsdl`.
This may or may not work well, depending on your shell and the spec content.

Similarly, you can use `api_policy_xml` to set the API level policy as XML.
To pass an URL to XML file instead, set `api_policy_format=rawxml-link`.
