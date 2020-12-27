terraform {
  backend "azurerm" {
    key = "terraform.tfstate"
  }

  required_providers {
    azurerm = "~> 2.40.0"
  }

  required_version = "~> 0.14"
}

provider "azurerm" {
  features {}
}
