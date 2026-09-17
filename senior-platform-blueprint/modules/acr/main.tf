# Azure Container Registry — stores Docker images your AKS cluster pulls.
#
# Design decisions:
#   * admin_enabled = false always. Nodes authenticate via managed identity
#     (AcrPull role on the kubelet identity), never via username/password.
#   * Private endpoint optional — dev skips it (cost), staging/prod require it
#     so image traffic never leaves the VNet.
#   * Premium SKU required for private endpoints. Standard used in dev.

resource "azurerm_container_registry" "this" {
  name                = "${replace(var.project, "-", "")}${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false

  # Zone redundancy only available on Premium. Prod needs it; dev/staging don't.
  zone_redundancy_enabled = var.zone_redundancy_enabled

  tags = var.tags
}

# AKS nodes pull images using the kubelet managed identity. This role assignment
# is the link between the cluster and the registry — no credentials anywhere.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = var.kubelet_identity_object_id
}

# --- Private endpoint (staging + prod only) ---
# Makes the registry reachable only from inside the VNet. Without this, image
# pulls go over the public internet even from a private AKS cluster.

resource "azurerm_private_dns_zone" "acr" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                  = "${var.project}-${var.environment}-acr-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "acr" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                = "${var.project}-${var.environment}-acr-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.project}-${var.environment}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.this.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr[0].id]
  }

  tags = var.tags
}
