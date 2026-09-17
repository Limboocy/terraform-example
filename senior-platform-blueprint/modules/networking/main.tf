# Network foundation for one environment.
#
# Layout:
#   VNet
#    ├── aks subnet          (node pools; Azure CNI consumes IPs here)
#    └── private-endpoints   (private links to PaaS: ACR, Key Vault, SQL, ...)
#
# Posture: NSG on the AKS subnet is deny-inbound-by-default. AKS itself needs
# no inbound rules for a standard LB setup — ingress arrives via the managed
# load balancer, which AKS programs. We only open what the environment declares.

resource "azurerm_resource_group" "this" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.project}-${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "${var.project}-${var.environment}-aks-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "${var.project}-${var.environment}-pe-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.pe_subnet_cidr]
}

resource "azurerm_network_security_group" "aks" {
  name                = "${var.project}-${var.environment}-aks-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  # Deny-by-default at the lowest inbound priority. Environment-specific allow
  # rules (priority < 4096) are injected via var.extra_inbound_rules.
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.extra_inbound_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# NSG flow logs into Log Analytics — required for network audit/forensics and
# to satisfy the "observability + compliance" side of the platform.
resource "azurerm_network_watcher_flow_log" "aks" {
  count = var.enable_flow_logs ? 1 : 0

  name                 = "${var.project}-${var.environment}-aks-flowlog"
  network_watcher_name = var.network_watcher_name
  resource_group_name  = var.network_watcher_resource_group

  network_security_group_id = azurerm_network_security_group.aks.id
  storage_account_id        = var.flow_log_storage_account_id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = var.flow_log_retention_days
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.log_analytics_workspace_guid
    workspace_region      = var.location
    workspace_resource_id = var.log_analytics_workspace_id
    interval_in_minutes   = 10
  }

  tags = var.tags
}
