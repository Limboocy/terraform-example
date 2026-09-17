resource "azurerm_resource_group" "this" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.location

  tags = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.project}-${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
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

  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_network_security_group" "aks" {
  name                = "${var.project}-${var.environment}-aks-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  # Deny-by-default. Add explicit allow rules below as needed —
  # do not open inbound ranges wider than the calling environment requires.
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

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}
