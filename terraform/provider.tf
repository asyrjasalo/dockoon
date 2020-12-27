terraform {
  backend "azurerm" {}

  required_providers {
    azurerm = "~> 2.40.0"
    null    = "~> 3.0.0"
  }
  required_version = "~> 0.14"
}

provider "azurerm" {
  features {}
}
