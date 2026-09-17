output "id" {
  value = azurerm_container_registry.this.id
}

output "name" {
  value = azurerm_container_registry.this.name
}

output "login_server" {
  description = "The URL your CI/CD pushes images to, e.g. aksplatformdevacr.azurecr.io"
  value       = azurerm_container_registry.this.login_server
}
