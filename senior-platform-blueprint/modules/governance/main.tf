# Governance as code: enforce organizational tagging on the environment's
# resource group scope using built-in Azure Policy definitions. This is the
# "compliance and governance requirements" responsibility, done preventively
# (deny/modify at deploy time) rather than via after-the-fact audit.

# Built-in policy: require a specific tag on resources. Looked up by name so we
# don't hardcode the definition GUID.
data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag on resources"
}

# Built-in initiative would be cleaner at scale; a single assignment per required
# tag keeps this readable for a learning blueprint.
resource "azurerm_resource_group_policy_assignment" "require_tags" {
  for_each = toset(var.required_tags)

  name                 = substr("require-${each.value}", 0, 24)
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.require_tag.id
  display_name         = "Require '${each.value}' tag"
  description          = "Denies resource creation without the '${each.value}' tag."

  parameters = jsonencode({
    tagName = { value = each.value }
  })
}
