output "budget_id" {
  value = azurerm_consumption_budget_resource_group.this.id
}

output "action_group_id" {
  value = azurerm_monitor_action_group.cost.id
}
