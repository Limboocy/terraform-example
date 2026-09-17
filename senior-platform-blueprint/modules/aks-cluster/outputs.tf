output "cluster_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "cluster_fqdn" {
  description = "Private FQDN when private_cluster_enabled, else public FQDN."
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "kubelet_identity_object_id" {
  description = "Kubelet managed identity — grant it AcrPull, Key Vault access, etc."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "cluster_identity_principal_id" {
  value = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "oidc_issuer_url" {
  description = "Used to configure federated identity credentials for workload identity."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_resource_group" {
  description = "The MC_ resource group AKS manages node resources in."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

# NOTE: kube_config_raw is deliberately NOT exported. With local_account_disabled
# and Azure RBAC, cluster access is via `az aks get-credentials` + Entra auth,
# not a static kubeconfig persisted in Terraform state.
