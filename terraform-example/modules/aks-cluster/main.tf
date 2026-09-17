resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.project}-${var.environment}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # System pool: only runs Kubernetes control-plane-adjacent workloads.
  # Application workloads go in a separate user node pool below —
  # never mix system and app workloads on the same pool.
  default_node_pool {
    name                = "system"
    vm_size             = var.system_vm_size
    vnet_subnet_id      = var.subnet_id
    only_critical_addons_enabled = true

    auto_scaling_enabled = true
    min_count           = var.system_min_count
    max_count           = var.system_max_count
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    load_balancer_sku = "standard"
  }

  # Azure AD integration — do not manage cluster access via static
  # kubeconfig admin credentials in anything above dev.
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = var.environment != "dev"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count, # autoscaler owns this after creation
    ]
  }

  tags = var.tags
}

# Separate user node pool for application workloads
resource "azurerm_kubernetes_cluster_node_pool" "app" {
  name                  = "app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.app_vm_size
  vnet_subnet_id        = var.subnet_id

  auto_scaling_enabled = true
  min_count           = var.app_min_count
  max_count           = var.app_max_count

  node_labels = {
    role = "app"
  }

  tags = var.tags
}
