# Conftest/OPA policies evaluated against a `terraform show -json tfplan`
# output in CI. These are a second, tool-independent guardrail on top of tfsec/
# checkov — they encode THIS org's rules, not generic CIS checks.
#
# Usage:
#   terraform show -json tfplan > plan.json
#   conftest test plan.json --policy policy/opa

package main

import rego.v1

# All planned AKS clusters in the change.
aks_clusters contains rc if {
	some rc in input.resource_changes
	rc.type == "azurerm_kubernetes_cluster"
	rc.change.actions[_] != "delete"
}

# Local admin account must be disabled everywhere.
deny contains msg if {
	some rc in aks_clusters
	rc.change.after.local_account_disabled == false
	msg := sprintf("AKS '%s': local_account_disabled must be true (Entra ID only).", [rc.address])
}

# An admin group must be bound — otherwise nobody can administer the cluster.
deny contains msg if {
	some rc in aks_clusters
	count(rc.change.after.azure_active_directory_role_based_access_control) == 0
	msg := sprintf("AKS '%s': Azure AD RBAC block with an admin group is required.", [rc.address])
}

# System pool must be zone-redundant unless it's explicitly a dev cluster.
deny contains msg if {
	some rc in aks_clusters
	not is_dev(rc)
	pool := rc.change.after.default_node_pool[0]
	count(pool.zones) < 2
	msg := sprintf("AKS '%s': non-dev clusters must span >= 2 availability zones.", [rc.address])
}

is_dev(rc) if endswith(rc.change.after.name, "-dev-aks")
