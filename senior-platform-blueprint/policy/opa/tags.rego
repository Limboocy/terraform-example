# Preventive tag governance in CI (complements the Azure Policy assignments that
# enforce at the cloud control plane). Catches missing tags before apply, when
# the feedback loop is a PR comment instead of a failed deployment.

package main

import rego.v1

required_tags := {"project", "environment", "managed_by", "cost_center"}

# Resource types we expect to carry the org tag set.
taggable := {
	"azurerm_kubernetes_cluster",
	"azurerm_virtual_network",
	"azurerm_resource_group",
	"azurerm_log_analytics_workspace",
}

deny contains msg if {
	some rc in input.resource_changes
	taggable[rc.type]
	rc.change.actions[_] != "delete"
	provided := object.keys(object.get(rc.change.after, "tags", {}))
	missing := required_tags - {t | some t in provided}
	count(missing) > 0
	msg := sprintf("%s '%s' is missing required tags: %v", [rc.type, rc.address, missing])
}
