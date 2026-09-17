# AKS cluster — production-grade baseline.
#
# Design principles encoded here (each maps to a real practice, not a toggle
# for its own sake):
#   * HA by construction: node pools are spread across availability zones and
#     prod runs a paid control-plane SLA (sku_tier = Standard/Premium).
#   * Least-privilege access: local admin account disabled, access flows only
#     through Entra ID (Azure AD) group membership + Azure RBAC.
#   * Private by default: the API server is not exposed to the internet in
#     staging/prod; dev may use authorized IP ranges instead.
#   * Managed lifecycle: auto patch upgrades inside a controlled maintenance
#     window, so security patching does not require a human every month.
#   * Defence in depth: Azure Policy add-on, Microsoft Defender, workload
#     identity (no static SPs), and the Key Vault CSI driver are all on.

locals {
  # A single node pool cannot span zones unless the region supports them.
  # Callers pass the zones they've validated for the target region.
  system_pool_name = "system"
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.project}-${var.environment}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # Paid tier gives an uptime SLA on the API server. Free tier has none —
  # unacceptable for anything above dev.
  sku_tier = var.sku_tier

  # Security patching without a human in the loop, but only during the window
  # the platform team owns. node-image + patch keeps us current without
  # jumping minor versions unexpectedly.
  automatic_channel_upgrade = var.automatic_channel_upgrade

  # API server exposure. Private cluster = API server reachable only from the
  # VNet (and peered/expressroute networks). Dev can stay public but locked to
  # known egress IPs.
  private_cluster_enabled = var.private_cluster_enabled
  private_dns_zone_id     = var.private_cluster_enabled ? "System" : null

  dynamic "api_server_access_profile" {
    for_each = var.private_cluster_enabled ? [] : [1]
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # Access model: no local admin kubeconfig, Entra ID groups only.
  local_account_disabled = var.local_account_disabled

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  # System pool: control-plane-adjacent add-ons only. Application workloads
  # live in the user pool below and must never be scheduled here.
  default_node_pool {
    name                         = local.system_pool_name
    vm_size                      = var.system_vm_size
    vnet_subnet_id               = var.subnet_id
    only_critical_addons_enabled = true
    orchestrator_version         = var.kubernetes_version

    # HA: spread system nodes across zones so a single AZ outage cannot take
    # out the control-plane add-ons.
    zones = var.availability_zones

    enable_auto_scaling = true
    min_count           = var.system_min_count
    max_count           = var.system_max_count
    max_pods            = var.max_pods
    os_disk_size_gb     = var.os_disk_size_gb
    os_sku              = "Ubuntu"

    # Lets Terraform recreate the pool in place when immutable fields change
    # instead of failing the apply.
    temporary_name_for_rotation = "systmp"

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Entra Workload Identity: pods federate to Entra ID directly. Removes the
  # need for static service-principal secrets in the cluster.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    outbound_type     = var.outbound_type
  }

  # Observability: ship container/node logs to Log Analytics using managed
  # identity auth (no workspace keys on the node).
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  # Governance + security add-ons.
  azure_policy_enabled = true

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Controlled auto-upgrade window: Sundays 02:00, 4h. Patch storms hit here,
  # not at 3pm on a Tuesday.
  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }

  lifecycle {
    ignore_changes = [
      # Autoscaler owns node_count after creation; Terraform must not fight it.
      default_node_pool[0].node_count,
      # kubernetes_version drifts upward via automatic_channel_upgrade; don't
      # let a stale pinned value trigger a downgrade plan.
      kubernetes_version,
    ]
  }

  tags = var.tags
}

# Application workloads. Separate pool so app churn never risks the system
# add-ons, and so app nodes can be sized/tainted independently.
resource "azurerm_kubernetes_cluster_node_pool" "app" {
  name                  = "app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.app_vm_size
  vnet_subnet_id        = var.subnet_id
  mode                  = "User"
  orchestrator_version  = var.kubernetes_version

  zones = var.availability_zones

  enable_auto_scaling = true
  min_count           = var.app_min_count
  max_count           = var.app_max_count
  max_pods            = var.max_pods
  os_disk_size_gb     = var.os_disk_size_gb
  os_sku              = "Ubuntu"

  node_labels = {
    role = "app"
  }

  # Keeps random system daemons off app nodes unless they tolerate it.
  node_taints = var.app_node_taints

  upgrade_settings {
    max_surge = "33%"
  }

  lifecycle {
    ignore_changes = [node_count]
  }

  tags = var.tags
}
