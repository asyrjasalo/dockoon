terraform {
  backend "azurerm" {
    resource_group_name  = "aswe-infra-dockoon-rg"
    storage_account_name = "asweinfradockoonsa"
    container_name       = "" # partial configuration
    key                  = "terraform.tfstate"
  }
}
