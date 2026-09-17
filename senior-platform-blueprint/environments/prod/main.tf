locals {
  environment = "prod"

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
  vnet_cidr       = "10.30.0.0/16"
  aks_subnet_cidr = "10.30.1.0/24"
  pe_subnet_cidr  = "10.30.2.0/24"

  tags = local.common_tags
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  project             = var.project
  environment         = local.environment
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  retention_in_days   = 90 # longer in prod for incident/compliance review
  daily_quota_gb      = -1 # no cap in prod — never drop signal during an incident

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

  # Prod hardening
  sku_tier                = "Standard" # paid API-server SLA
  private_cluster_enabled = true       # no public API endpoint
  local_account_disabled  = true
  admin_group_object_ids  = var.aks_admin_group_object_ids
  availability_zones      = ["1", "2", "3"]

  # Sizing: bigger nodes, higher floor so a single node/zone loss keeps capacity.
  system_vm_size   = "Standard_D4s_v5"
  system_min_count = 2
  system_max_count = 5
  app_vm_size      = "Standard_D8s_v5"
  app_min_count    = 3
  app_max_count    = 20

  tags = local.common_tags
}

module "observability" {
  source = "../../modules/observability-datadog"

  environment       = local.environment
  cluster_name      = module.aks.cluster_name
  alert_channel     = "devops-alerts-prod"
  pagerduty_service = "aks-prod" # prod pages on-call, not just Slack
  priority          = 1
  renotify_interval = 15
  runbook_url       = "https://runbooks.internal/aks/prod"
}

module "cost" {
  source = "../../modules/cost-management"

  project             = var.project
  environment         = local.environment
  resource_group_name = module.networking.resource_group_name
  resource_group_id   = module.networking.resource_group_id
  monthly_budget      = 8000
  budget_start_date   = var.budget_start_date
  alert_emails        = var.cost_alert_emails

  tags = local.common_tags
}

module "governance" {
  source = "../../modules/governance"

  resource_group_id = module.networking.resource_group_id
  required_tags     = ["project", "environment", "managed_by", "cost_center"]
}

# Prod: Premium SKU, zone-redundant storage, private endpoint. Images survive
# a zone failure and never traverse the public internet.
module "acr" {
  source = "../../modules/acr"

  project                    = var.project
  environment                = local.environment
  location                   = var.location
  resource_group_name        = module.networking.resource_group_name
  kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  sku                        = "Premium"
  zone_redundancy_enabled    = true
  private_endpoint_enabled   = true
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id
  vnet_id                    = module.networking.vnet_id

  tags = local.common_tags
}

# Prod: purge protection on — a deleted vault cannot be permanently destroyed
# for 90 days, protecting production secrets from accidental or malicious loss.
module "keyvault" {
  source = "../../modules/keyvault"

  project                    = var.project
  environment                = local.environment
  location                   = var.location
  resource_group_name        = module.networking.resource_group_name
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  private_endpoint_enabled   = true
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id
  vnet_id                    = module.networking.vnet_id

  tags = local.common_tags
}
