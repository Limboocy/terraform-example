output "policy_assignment_ids" {
  value = { for k, v in azurerm_resource_group_policy_assignment.require_tags : k => v.id }
}
