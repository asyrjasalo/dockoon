# Running on Azure Container Instances and App Gateway

Note: This is not maintained over [../bicep/README.md](../bicep/README.md)
which allows running behind an API Management service.

## Prerequisites

The following tools are used locally:

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [tfenv](https://github.com/tfutils/tfenv) to install required Terraform version
- [tfvar](https://github.com/shihanng/tfvar) to generate new `environments/`
 
To install them on OS X:

    brew bundle

Use `tfenv` to install proper Terraform version (according to `provider.tf`):

    tfenv install

Login to Azure:

    az login

## Create Terraform backend (only once)

The "infra" resource group contains non-environment specific resources:

- Storage account with a container for each environment
- Key vault for storing the storage account key (and possibly other secrets)

Set names for the infra resources in `config.sh`, then run:

    backend/create_tf_backend.sh

The script creates `backend/*.backend` for test, stg and prod environments.

## Create or upgrade environment

Get `ARM_ACCESS_KEY` from infra Key vault and export it for TF Azure provider:

    source get_arm_access_key.sh

Install providers according to TF lockfile and catch up with the remote state:

    terraform init -backend-config=backend/test.backend -reconfigure -upgrade

Create `environments/test.tfvars` from `variables.tf` and fill empty variables:

    tfvar . > environments/test.tfvars

See `environments/*.example.tfvars` for examples to deploy in non-prod and prod.

Validate and output upcoming changes for the environment:

    terraform plan -var-file=environments/test.tfvars -out=test.tfplan

Apply the actual changes in Azure:

    terraform apply test.tfplan

### Container volume mount

Upload `apis.json` to the environment's Storage Account's File Share `apis`
to get the container running successfully.

Alternatively, you can set the Docker start command in `environments/*.tfvars`.

## Options

### ACI networking

A `/24` virtual network with `public` and `private` subnets is always present.

By default (`visibility = Private`) ACI is delegated into the `private` subnet.

Set `visibility = Public` to run ACI in public Internet (gets ACI's FQDN).

### Log Analytics Workspace

Set `law_sku = "PerGB2018"` to create a law and log there from the container.

Use queries:

    ContainerInstanceLog_CL | order by TimeGenerated desc
    ContainerEvent_CL | order by TimeGenerated desc

### Application Gateway

Set `enable_appgw = true` to respond from the standard HTTP ports (80, 443).

AppGw HTTPS requires `secrets/cert.pfx` to be created locally first.

Create a service principal for [Certbot](https://certbot.eff.org/)
DNS challenge:

    export SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
    export DNS_RESOURCE_GROUP_NAME="slug-common-dns-rg"
    
    az ad sp create-for-rbac \
        --name sp-dockoon-common-certbot \
        --sdk-auth \
        --role "DNS Zone Contributor" \
        --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$DNS_RESOURCE_GROUP_NAME" \
        > secrets/certbot-sp.json

Install certbot and [certbot-azure](https://github.com/dlapiduz/certbot-azure):

    pip install --upgrade certbot-azure

Obtain a certificate from Let's Encrypt:

    export YOUR_DOMAIN="dockoon.test.yourdomain.dev"
    export YOUR_EMAIL="yourmail@yourdomain.dev"

    certbot certonly \
        --config-dir=letsencrypt \
        --logs-dir=letsencrypt \
        --work-dir=letsencrypt \
        --email="$YOUR_EMAIL" \
        --agree-tos \
        -d "$YOUR_DOMAIN" \
        -a dns-azure \
        --dns-azure-credentials secrets/certbot-sp.json \
        --dns-azure-resource-group "$DNS_RESOURCE_GROUP_NAME"

Add parameters `--renew-by-default --text` if running the command in cron.

Create `secrets/cert.pfx` from the certbot outputted `letsencrypt/` files:

    openssl pkcs12 \
        -inkey "letsencrypt/live/$YOUR_DOMAIN/privkey.pem" \
        -in "letsencrypt/live/$YOUR_DOMAIN/cert.pem" \
        -export -out secrets/$YOUR_DOMAIN.pfx

Enter a password for certificate and define it as `cert_password` in `.tfvars`.

## Command reference

test:

    terraform init -backend-config=backend/test.backend -reconfigure -upgrade
    terraform apply -var-file=environments/test.tfvars -auto-approve

stg:

    terraform init -backend-config=backend/stg.backend -reconfigure -upgrade
    terraform apply -var-file=environments/stg.tfvars -auto-approve

prod:

    terraform init -backend-config=backend/prod.backend -reconfigure -upgrade
    terraform apply -var-file=environments/prod.tfvars -auto-approve
