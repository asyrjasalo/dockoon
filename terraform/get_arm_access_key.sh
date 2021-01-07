#!/usr/bin/env bash

### load config.sh #############################################################

if [ ! -f config.sh ]; then
  echo "ERROR: config.sh file missing"
  exit 1
fi

# shellcheck disable=SC1091
source config.sh

### set subscription ###########################################################

run_cmd az account set --subscription "$SUBSCRIPTION_ID"

### get storage account key ####################################################

ARM_ACCESS_KEY="$(az keyvault secret show \
    --name "$VAULT_STORAGE_ACCOUNT_KEY_NAME" \
    --vault-name "$VAULT_NAME" \
    --query value \
    --output tsv)"

### export variables ###########################################################

log_date "<Exporting variables>"

export ARM_ACCESS_KEY

### log variables ##############################################################

log_date "<Log variables>"

log_date "ARM_ACCESS_KEY=$ARM_ACCESS_KEY"
