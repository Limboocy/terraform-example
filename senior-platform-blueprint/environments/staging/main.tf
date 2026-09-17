locals {
  environment = "staging"

  common_tags = {
    project     = var.project
    environment = local.environment
    managed_by  = "terraform"
    cost_center = var.cost_center
    owner       = var.owner
  }
}

module "networking" {
  source = "../../modules/networking"

  project         = var.project
  environment     = local.environment
  location        = var.location
  vnet_cidr       = "10.20.0.0/16"
  aks_subnet_cidr = "10.20.1.0/24"
  pe_subnet_cidr  = "10.20.2.0/24"

  tags = local.common_tags
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  project             = var.project
  environment         = local.environment
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  retention_in_days   = 30
  daily_quota_gb      = 10

  tags = local.common_tags
}

module "aks" {
  source = "../../modules/aks-cluster"

  project                    = var.project
  environment                = local.environment
  location                   = var.location
  resource_group_name        = module.networking.resource_group_name
  subnet_id                  = module.networking.aks_subnet_id
  log_analytics_workspace_id = module.log_analytics.id

  sku_tier                = "Standard"
  private_cluster_enabled = true
  local_account_disabled  = true
  admin_group_object_ids  = var.aks_admin_group_object_ids
  availability_zones      = ["1", "2", "3"]

  system_vm_size   = "Standard_D2s_v5"
  system_min_count = 1
  system_max_count = 3
  app_vm_size      = "Standard_D4s_v5"
  app_min_count    = 2
  app_max_count    = 6

  tags = local.common_tags
}

module "observability" {
  source = "../../modules/observability-datadog"

  environment   = local.environment
  cluster_name  = module.aks.cluster_name
  alert_channel = "devops-alerts-staging"
  priority      = 3
  runbook_url   = "https://runbooks.internal/aks/staging"
}

module "cost" {
  source = "../../modules/cost-management"

  project             = var.project
  environment         = local.environment
  resource_group_name = module.networking.resource_group_name
  resource_group_id   = module.networking.resource_group_id
  monthly_budget      = 3000
  budget_start_date   = var.budget_start_date
  alert_emails        = var.cost_alert_emails

  tags = local.common_tags
}

module "governance" {
  source = "../../modules/governance"

  resource_group_id = module.networking.resource_group_id
  required_tags     = ["project", "environment", "managed_by", "cost_center"]
}

# Staging: Premium SKU (required for private endpoint), private endpoint on.
# Image pulls from AKS never leave the VNet.
module "acr" {
  source = "../../modules/acr"

  project                    = var.project
  environment                = local.environment
  location                   = var.location
  resource_group_name        = module.networking.resource_group_name
  kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  sku                        = "Premium"
  private_endpoint_enabled   = true
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id
  vnet_id                    = module.networking.vnet_id

  tags = local.common_tags
}

# Staging: private endpoint on, no purge protection (easier to clean up test vaults).
module "keyvault" {
  source = "../../modules/keyvault"

  project                    = var.project
  environment                = local.environment
  location                   = var.location
  resource_group_name        = module.networking.resource_group_name
  purge_protection_enabled   = false
  soft_delete_retention_days = 30
  private_endpoint_enabled   = true
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id
  vnet_id                    = module.networking.vnet_id

  tags = local.common_tags
}
