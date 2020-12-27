# Running on Azure Container Instances

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

Validate and output upcoming changes for the environment:

    terraform plan -var-file=environments/test.tfvars -out=test.tfplan

Apply the actual changes in Azure:

    terraform apply "test.tfplan"

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