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

  # Remote state in Azure Storage. Native blob leasing provides state locking.
  # The storage account is created once by ../../bootstrap (chicken-and-egg:
  # you cannot store the bootstrap's own state here until it exists).
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateplatform"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

# Datadog auth via env vars DD_API_KEY / DD_APP_KEY — never hardcode.
provider "datadog" {}
