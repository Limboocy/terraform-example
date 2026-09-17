# Azure Key Vault — stores secrets, certificates, and keys your apps need at
# runtime. AKS pods access it via the Key Vault CSI driver + workload identity
# (federated token, no passwords stored anywhere).
#
# Design decisions:
#   * RBAC authorization model, not the legacy access-policy model. RBAC lets
#     you audit and manage access through standard Azure IAM, and it composes
#     with Entra PIM for time-limited elevated access.
#   * Purge protection on in prod: a deleted vault cannot be permanently
#     destroyed for the retention period. Prevents accidental or malicious data
#     loss of production secrets.
#   * Private endpoint in staging/prod: vault traffic stays inside the VNet.
#     Dev uses network ACLs with IP allowlist instead (cheaper, lower friction).

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = "${var.project}-${var.environment}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization  = true
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days

  network_acls {
    # When private endpoint is on, deny everything by default — traffic only
    # enters through the private endpoint. When off (dev), allow from known IPs.
    default_action             = var.private_endpoint_enabled ? "Deny" : "Allow"
    bypass                     = "AzureServices"
    ip_rules                   = var.private_endpoint_enabled ? [] : var.allowed_ip_ranges
    virtual_network_subnet_ids = []
  }

  tags = var.tags
}

# Terraform's own identity needs Key Vault Administrator during apply so it can
# write secrets (e.g. if you use azurerm_key_vault_secret resources).
# Scoped to this vault only — not a subscription-wide grant.
resource "azurerm_role_assignment" "terraform_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# AKS workload identity: read-only secrets access. Pods federate their service
# account token to this identity; no static credential ever touches the pod.
resource "azurerm_role_assignment" "workload_identity_secrets_user" {
  count = var.workload_identity_object_id != null ? 1 : 0

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.workload_identity_object_id
}

# --- Private endpoint (staging + prod only) ---

resource "azurerm_private_dns_zone" "kv" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                  = "${var.project}-${var.environment}-kv-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "kv" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                = "${var.project}-${var.environment}-kv-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.project}-${var.environment}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv[0].id]
  }

  tags = var.tags
}
