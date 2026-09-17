module "networking" {
  source = "../../modules/networking"

  project         = var.project
  environment     = "prod"
  location        = var.location
  vnet_cidr       = "10.30.0.0/16"
  aks_subnet_cidr = "10.30.1.0/24"
  pe_subnet_cidr  = "10.30.2.0/24"

  tags = local.common_tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.project}-prod-law"
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 90 # prod keeps logs longer for incident/compliance review
}

module "aks" {
  source = "../../modules/aks-cluster"

  project                    = var.project
  environment                = "prod"
  location                   = var.location
  resource_group_name        = module.networking.resource_group_name
  subnet_id                  = module.networking.aks_subnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # Prod sizing — bigger nodes, wider autoscale ceiling, higher floor
  # so a single node loss doesn't take down capacity.
  system_vm_size   = "Standard_D4s_v5"
  system_min_count = 2
  system_max_count = 5
  app_vm_size      = "Standard_D8s_v5"
  app_min_count    = 3
  app_max_count    = 20

  tags = local.common_tags
}

module "monitors" {
  source = "../../modules/datadog-monitors"

  environment   = "prod"
  cluster_name  = module.aks.cluster_name
  alert_channel = "devops-alerts-prod" # prod pages a different channel than dev
}

locals {
  common_tags = {
    project     = var.project
    environment = "prod"
    managed_by  = "terraform"
  }
}
