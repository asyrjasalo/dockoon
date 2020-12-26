# Running on Azure Container Instances

## Prerequisites

Install [tfenv](https://github.com/tfutils/tfenv) and [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest):

    brew bundle

Use `tfenv` to install proper Terraform version according to `provider.tf`:

    tfenv install

Login to Azure:

    az login

## Create Terraform backend (only once)

The infra resource group contains non-environment specific resorces:

- Storage account with a container for each environment
- Key vault for storing the storage account key (and possibly other secrets)

Put names for the infra resources in `config.sh` and run:

    backend/create_tf_backend.sh

Configure variables in `backend/*.backend` files accordingly.

## Create or upgrade environment

Get `ARM_ACCESS_KEY` from the infra Key vault and export it for Azure provider:

    source get_arm_access_key.sh

Install providers according to the lockfile and catch up with the remote state:

    terraform init -backend-config=backend/test.backend -reconfigure

Validate and output changes for the environment:

    terraform plan -var-file=environments/test.tfvars -out=test.tfplan

Apply the actual changes in Azure:

    terraform apply "test.tfplan"
