module "networking" {
  source = "../../modules/networking"

  project         = var.project
  environment     = "staging"
  location        = var.location
  vnet_cidr       = "10.20.0.0/16"
  aks_subnet_cidr = "10.20.1.0/24"
  pe_subnet_cidr  = "10.20.2.0/24"

  tags = local.common_tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.project}-staging-law"
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

module "aks" {
  source = "../../modules/aks-cluster"

  project                    = var.project
  environment                = "staging"
  location                   = var.location
  resource_group_name        = module.networking.resource_group_name
  subnet_id                  = module.networking.aks_subnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  system_vm_size = "Standard_D2s_v5"
  app_vm_size    = "Standard_D4s_v5"
  app_min_count  = 2
  app_max_count  = 6

  tags = local.common_tags
}

module "monitors" {
  source = "../../modules/datadog-monitors"

  environment   = "staging"
  cluster_name  = module.aks.cluster_name
  alert_channel = "devops-alerts-staging"
}

locals {
  common_tags = {
    project     = var.project
    environment = "staging"
    managed_by  = "terraform"
  }
}
