output "cluster_name" {
  value = module.aks.cluster_name
}

output "cluster_fqdn" {
  value = module.aks.cluster_fqdn
}

output "resource_group" {
  value = module.networking.resource_group_name
}

output "dashboard_url" {
  value = module.observability.dashboard_url
}

output "acr_login_server" {
  description = "Push images here from CI: docker push <acr_login_server>/myapp:tag"
  value       = module.acr.login_server
}

output "keyvault_uri" {
  description = "Reference this URI in the CSI driver SecretProviderClass manifest."
  value       = module.keyvault.uri
}
