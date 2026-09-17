output "monitor_ids" {
  value = {
    node_cpu_high      = datadog_monitor.node_cpu_high.id
    pod_crashloop      = datadog_monitor.pod_crashloop.id
    node_disk_pressure = datadog_monitor.node_disk_pressure.id
  }
}

output "slo_id" {
  value = datadog_service_level_objective.pod_availability.id
}

output "dashboard_url" {
  value = datadog_dashboard_json.aks_overview.url
}
