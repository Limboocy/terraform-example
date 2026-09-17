locals {
  environment = "dev"

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
  vnet_cidr       = "10.10.0.0/16"
  aks_subnet_cidr = "10.10.1.0/24"
  pe_subnet_cidr  = "10.10.2.0/24"

  tags = local.common_tags
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  project             = var.project
  environment         = local.environment
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  retention_in_days   = 30
  daily_quota_gb      = 5 # tight cap — cost control matters most in dev

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

  # Dev tradeoffs: cheaper Free tier, public API server locked to office/VPN
  # egress IPs (private cluster adds cost + friction not worth it in dev).
  sku_tier                        = "Free"
  private_cluster_enabled         = false
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  local_account_disabled          = true
  admin_group_object_ids          = var.aks_admin_group_object_ids
  availability_zones              = ["1"] # single zone — dev doesn't need HA

  system_vm_size   = "Standard_D2s_v5"
  system_min_count = 1
  system_max_count = 3
  app_vm_size      = "Standard_D2s_v5"
  app_min_count    = 1
  app_max_count    = 3

  tags = local.common_tags
}

module "observability" {
  source = "../../modules/observability-datadog"

  environment   = local.environment
  cluster_name  = module.aks.cluster_name
  alert_channel = "devops-alerts-dev"
  priority      = 4
  runbook_url   = "https://runbooks.internal/aks/dev"
}

module "cost" {
  source = "../../modules/cost-management"

  project             = var.project
  environment         = local.environment
  resource_group_name = module.networking.resource_group_name
  resource_group_id   = module.networking.resource_group_id
  monthly_budget      = 800
  budget_start_date   = var.budget_start_date
  alert_emails        = var.cost_alert_emails

  tags = local.common_tags
}

module "governance" {
  source = "../../modules/governance"

  resource_group_id = module.networking.resource_group_id
  required_tags     = ["project", "environment", "managed_by", "cost_center"]
}

# Dev: Standard SKU (cheaper), no private endpoint. Nodes still authenticate
# via managed identity — admin_enabled stays false inside the module.
module "acr" {
  source = "../../modules/acr"

  project                    = var.project
  environment                = local.environment
  location                   = var.location
  resource_group_name        = module.networking.resource_group_name
  kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  sku                        = "Standard"
  private_endpoint_enabled   = false

  tags = local.common_tags
}

# Dev: no private endpoint, IP allowlist only, no purge protection.
module "keyvault" {
  source = "../../modules/keyvault"

  project                    = var.project
  environment                = local.environment
  location                   = var.location
  resource_group_name        = module.networking.resource_group_name
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  private_endpoint_enabled   = false
  allowed_ip_ranges          = var.api_server_authorized_ip_ranges

  tags = local.common_tags
}
