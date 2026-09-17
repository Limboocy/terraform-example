# One-time bootstrap: creates the Azure Storage account that holds every other
# environment's remote state. This is the chicken-and-egg root of the platform.
#
# Apply this FIRST, with local state, then commit the resulting names into each
# environment's backend "azurerm" block. Its own state can stay local (checked
# into a secured location) or be migrated into the container it creates.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "state_resource_group" {
  type    = string
  default = "tfstate-rg"
}

variable "state_storage_account" {
  type        = string
  default     = "tfstateplatform"
  description = "Must be globally unique, 3-24 lowercase alphanumeric chars."
}

resource "azurerm_resource_group" "state" {
  name     = var.state_resource_group
  location = var.location

  tags = {
    purpose    = "terraform-state"
    managed_by = "terraform"
  }
}

resource "azurerm_storage_account" "state" {
  name                     = var.state_storage_account
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # geo-redundant: state survives a region loss

  # Security hardening for a high-value store.
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false # force Entra ID (AAD) auth, no keys

  blob_properties {
    versioning_enabled = true # recover from a bad state write
    delete_retention_policy {
      days = 30
    }
  }

  tags = {
    purpose    = "terraform-state"
    managed_by = "terraform"
  }
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"
}

output "backend_config" {
  description = "Copy these into each environment's backend block."
  value = {
    resource_group_name  = azurerm_resource_group.state.name
    storage_account_name = azurerm_storage_account.state.name
    container_name       = azurerm_storage_container.state.name
  }
}
