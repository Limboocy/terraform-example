output "id" {
  description = "ARM resource ID of the workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_guid" {
  description = "The workspace GUID (needed by traffic analytics)."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "name" {
  value = azurerm_log_analytics_workspace.this.name
}
