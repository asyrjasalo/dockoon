terraform {
  backend "azurerm" {
    key = "terraform.tfstate"
  }

  required_providers {
    azurerm = "= 2.66.0"
  }

  required_version = "~> 1.0"
}

provider "azurerm" {
  features {}
}
