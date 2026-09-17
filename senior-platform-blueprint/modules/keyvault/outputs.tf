output "id" {
  value = azurerm_key_vault.this.id
}

output "name" {
  value = azurerm_key_vault.this.name
}

output "uri" {
  description = "The vault URI. Pods reference this when mounting secrets via the CSI driver."
  value       = azurerm_key_vault.this.vault_uri
}
