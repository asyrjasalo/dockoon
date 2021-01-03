# On Azure Container Instances (+ Application Gateway)

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

Configure remote state resource names in `backend/*.backend` files accordingly.

## Create or upgrade environment

Get `ARM_ACCESS_KEY` from infra Key vault and export it for TF Azure provider:

    source get_arm_access_key.sh

Install providers according to TF lockfile and catch up with the remote state:

    terraform init -backend-config=backend/test.backend -reconfigure

Create `environments/test.tfvars` from `variables.tf` and fill empty variables:

    tfvar . > environments/test.tfvars

See `environments/*.example.tfvars` for examples to deploy in VNET or without.

Validate and output upcoming changes for the environment:

    terraform plan -var-file=environments/test.tfvars -out=test.tfplan

Apply the actual changes in Azure:

    terraform apply "test.tfplan"

### Container volume mount

Upload `apis.json` to the environment's Storage Account's File Share `apis`
to get the container running successfully.

Alternatively, you can set the Docker start command in `environments/*.tfvars`.

## Options

### Networking

A `/24` virtual network with `public` and `private` subnets is always present.

### ACI visiblity

By default, ACI is deployed/delegated into the VNET's `private` subnet.

Set `visibility = Public` to run ACI in public Internet (gets ACI's FQDN).

### Log Analytics Workspace

Set `law_sku = "PerGB2018"` to create a law and log there from the container.

Use queries:

    ContainerInstanceLog_CL | order by TimeGenerated desc
    ContainerEvent_CL | order by TimeGenerated desc

### Application Gateway

Set `enable_appgw = true` to forward standard HTTP (80) to the container port.

Enabling HTTPS requires custom certificate (`.pfx`) to be created and uploaded
to the AppGw (not part of Terraform modules).

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