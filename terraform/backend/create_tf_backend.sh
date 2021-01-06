#!/usr/bin/env bash

set -eu

this_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$this_path/../config.sh" ]; then
  echo "ERROR: config.sh file is missing"
  exit 1
fi

# shellcheck disable=SC1090
source "$this_path/../config.sh"

# Set subscription
run_cmd az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group
run_cmd az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"

# Create storage account
run_cmd az storage account create --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$STORAGE_ACCOUNT_NAME" \
  --sku Standard_LRS \
  --encryption-services blob \
  --location "$LOCATION"

# Get storage account key
storage_account_key=$(az storage account keys list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --query [0].value -o tsv)

# Create key vault
run_cmd az keyvault create --name "$VAULT_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION"

# Save storage account key to key vault
run_cmd az keyvault secret set --name "$VAULT_STORAGE_ACCOUNT_KEY_NAME" \
  --vault-name "$VAULT_NAME" \
  --value "$storage_account_key"

# Create storage containers for environments
run_cmd az storage container create --name "test" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --account-key "$storage_account_key"

echo "resource_group_name  = \"$RESOURCE_GROUP_NAME\"" > "$this_path/test.backend"
echo "storage_account_name = \"$STORAGE_ACCOUNT_NAME\"" >> "$this_path/test.backend"
echo "container_name = \"test\"" >> "$this_path/test.backend"

run_cmd az storage container create --name "stg" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --account-key "$storage_account_key"

echo "resource_group_name  = \"$RESOURCE_GROUP_NAME\"" > "$this_path/stg.backend"
echo "storage_account_name = \"$STORAGE_ACCOUNT_NAME\"" >> "$this_path/stg.backend"
echo "container_name = \"stg\"" >> "$this_path/stg.backend"

run_cmd az storage container create --name "prod" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --account-key "$storage_account_key"

echo "resource_group_name  = \"$RESOURCE_GROUP_NAME\"" > "$this_path/prod.backend"
echo "storage_account_name = \"$STORAGE_ACCOUNT_NAME\"" >> "$this_path/prod.backend"
echo "container_name = \"prod\"" >> "$this_path/prod.backend"
