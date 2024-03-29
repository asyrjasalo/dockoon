# Running on Azure Container Instances and API Management

This `README.md` summarizes [the blog post from 2021-07-08](https://rise.raas.dev/apis-one-command/).

We will create the following in your Azure subscription:

- Container Instance for running e.g. [Mockoon](https://mockoon.com/) APIs
- Storage Account for API specs and a share to use as a container volume mount
- Public API Management service incl. Portal, AppInsights and Log Analytics
- Authenticated HTTPS API from OpenAPI spec, containerized API as the backend
- TLS certificates for HTTPS with automated renewal to a key vault

![Azure Architecture](../docs/azure_architecture.png)

Principles:

- PaaS over virtual machines, Kubernetes, ingresses and API gateway software
- Use the cheapest option for running container workloads in a private network
- On Azure, have full ARM compatibility without actually writing any JSON
- Deployments ought not to have state management (e.g. Terraform and Pulumi)
- Deployments ought to be **one command** not requiring more than Azure CLI

## Prerequisites

### Domain name

You must own a domain which is delegated to an existing public DNS zone in the same Azure subscription.

ACI deployment will create DNS record (A) for the Container Instance app.
Also 3 CNAME records for API Gateway, Developer Portal and Management API
are created in the DNS zone and set as custom domains by APIM deployment.

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

If you do not have Bash available for your OS, you can clone this repo in
Azure Cloud Shell and run the commands there.

Alternatively, you can [create the CI/CD pipeline](../docs/cicd.md) in your
Azure DevOps project and run the pipeline.

## Deploy

We will use pure env vars over `azuredeploy.parameters.json`, var files, etc.

Copy `prod.env.example` to `prod.env` and configure variables.

Note that DNS and key vault specific *deployments* (`dns.bicep` and `kv.bicep`)
will be created in their own configured resource groups and thus visible there.

### Shortcut

To get everything up(dated) with one command according to the steps below:

    ./deploy prod.env ../apis.json ../openapi.json

### Steps

Export the variables:

    set -a; source prod.env; set +a

Create a target resource group:

    az group create \
        --name "$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-rg" \
        --location "$AZ_LOCATION" \
        --subscription "$AZ_SUBSCRIPTION_ID" \
        --tags app="$AZ_APP" environment="$AZ_ENVIRONMENT" owner="$AZ_OWNER"

Create storage account for the API files:

    az deployment group create \
        --resource-group "$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-rg" \
        --subscription "$AZ_SUBSCRIPTION_ID" \
        --template-file sa.bicep \
        -p sa_name="${AZ_PREFIX//-/}${AZ_ENVIRONMENT//-/}${AZ_APP//-/}sa" \
        -p tags="{'app': '$AZ_APP', 'environment': '$AZ_ENVIRONMENT', 'owner': '$AZ_OWNER'}"

Upload `apis.json` to the storage account file share for the container:

    az storage file upload \
        --account-name "${AZ_PREFIX//-/}${AZ_ENVIRONMENT//-/}${AZ_APP//-/}sa" \
        --share-name share \
        --source ../apis.json

Create deployment in the resource group:

    az deployment group create \
        --subscription "$AZ_SUBSCRIPTION_ID" \
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

Note that initially creating an API Management service might take half an hour.

Upload `openapi.json` to the storage account blob container for the APIM:

    az storage blob upload \
        --account-name "${AZ_PREFIX//-/}${AZ_ENVIRONMENT//-/}${AZ_APP//-/}sa" \
        --container-name apis \
        --name openapi.json \
        --file ../openapi.json

Deploy (or update) API in APIM from the OpenAPI specification:

    az deployment group create \
        --resource-group "$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-rg" \
        --subscription "$AZ_SUBSCRIPTION_ID" \
        --template-file api.bicep \
        -p apim_name="$AZ_PREFIX-$AZ_ENVIRONMENT-$AZ_APP-apim" \
        -p app_name="$AZ_APP" \
        -p api_backend_url="http://$AZ_APP-$AZ_ENVIRONMENT.$AZ_DNS_ZONE_NAME:8080" \
        -p api_spec="https://${AZ_PREFIX//-/}${AZ_ENVIRONMENT//-/}${AZ_APP//-/}sa.blob.core.windows.net/apis/openapi.json"

Verify the API responds 200 (OK) when called with API Management Gateway URL:

    curl https://api.${AZ_DNS_ZONE_NAME}/dockoon/v1/users \
        --header 'Ocp-Apim-Subscription-Key: {{subscription_key_for_app}}'

## API management

This chapter briefly summarizes some good operational practices.

### Portal

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

Deployment of `api.bicep` comes with sensible defaults, such as HTTPS only,
but based on your purposes you may adjust parameters, most important of which
are documented below.

### Version

The API display name is taken from the API spec and the product name is taken
from `app_name`. You can optionally configure parameters `app_description` and 
`app_terms` for the product, and `api_description` for the API.

By default, API version set named 'v1' is created and the version is carried
as part of the URL. To deploy a new API version, set e.g. `api_version=v2`.

### Revision

By default, **revision 1 is set as current**, which may not be desired in
production. If you want to implement canary, create a new revision `2`, set 
`api_set_current=false` and set revision `2` as current when suitable.

### Subscription

If you want to require **no authentication** for the particular API deployed, 
add `api_require_auth=false`. Authentication is still required on the product 
level for the other APIs that are possibly assigned in the product.

If you want to require **no approval from Administrators** when new users
subscribe to the product, add `app_require_admin_approval=false`.

### Spec

OpenAPI (3.x), Swagger (2.x) and WSDL specification formats can be imported by
API Management. If are deploying a SOAP API instead of REST, add 
`api_type=soap` and use `api_format=wsdl-link` with `api_spec` URL to the XML.

If you want to read `api_spec` content directly as a parameter,
set `api_format` to `openapi-json`, `swagger-json` or `wsdl`.
This may or may not work well, depending on your shell and the spec content.

### Policy

API management policies can be set on service, product or API level.
By default, rate-limit policy is created on the API level by `api.bicep`.

You can set `api_policy_xml` to override the API level policy as XML content.
To pass an URL to an XML file instead of the content, also set
`api_policy_format=rawxml-link`.
