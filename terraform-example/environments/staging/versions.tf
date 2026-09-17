terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.45"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateacctname"
    container_name       = "tfstate"
    key                  = "staging.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Datadog provider auth comes from env vars, never hardcode here:
#   DD_API_KEY, DD_APP_KEY
provider "datadog" {}
