#!/usr/bin/env bash
# shellcheck disable=SC2034

### Configure below ############################################################

# Existing subscription ID
SUBSCRIPTION_ID='f702f7f3-08cc-49da-9199-6586218f1e03'

# Region for the rg
LOCATION='WestEurope'

# Where all resources go
RESOURCE_GROUP_NAME='aswe-infra-dockoon-rg'

# Storage account for terraform states
STORAGE_ACCOUNT_NAME='asweinfradockoonsa'

# Key vault for storing the storage account key
VAULT_NAME='aswe-infra-dockoon-kv'
VAULT_STORAGE_ACCOUNT_KEY_NAME='aswe-infra-dockoon-tfstate-key'

### Common helpers #############################################################

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

log_date() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&1
}

run_cmd() {
  "$@" 2>&1| tee -a infra.log

  ret=$?
  if [[ $ret -eq 0 ]]; then
    log_date "Ran [ $* ]"
  else
    err "Error: Command [ $* ] returned $ret"
    exit $ret
  fi
}
