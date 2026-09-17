resource "datadog_monitor" "node_cpu_high" {
  name    = "[${var.environment}] AKS node CPU > 85%"
  type    = "metric alert"
  message = <<-EOT
    {{#is_alert}}
    Node CPU usage is above threshold on cluster ${var.cluster_name}.
    @slack-${var.alert_channel}
    {{/is_alert}}
    {{#is_recovery}}
    Node CPU usage back to normal on ${var.cluster_name}.
    {{/is_recovery}}
  EOT

  query = "avg(last_5m):avg:kubernetes.cpu.usage.total{cluster_name:${var.cluster_name}} by {node} > 85"

  monitor_thresholds {
    critical = 85
    warning  = 70
  }

  notify_no_data    = true
  no_data_timeframe = 20
  tags              = ["env:${var.environment}", "cluster:${var.cluster_name}"]
}

resource "datadog_monitor" "pod_crashloop" {
  name    = "[${var.environment}] Pod CrashLoopBackOff on ${var.cluster_name}"
  type    = "event alert"
  message = <<-EOT
    {{#is_alert}}
    Pods are crash-looping on ${var.cluster_name}.
    @slack-${var.alert_channel}
    {{/is_alert}}
  EOT

  query = "events('sources:kubernetes status:error priority:normal \"CrashLoopBackOff\" cluster_name:${var.cluster_name}').rollup('count').last('5m') > 3"

  tags = ["env:${var.environment}", "cluster:${var.cluster_name}"]
}

resource "datadog_monitor" "pvc_disk_pressure" {
  name    = "[${var.environment}] Node disk pressure on ${var.cluster_name}"
  type    = "metric alert"
  message = <<-EOT
    {{#is_alert}}
    Disk usage is critical on a node in ${var.cluster_name}.
    @slack-${var.alert_channel}
    {{/is_alert}}
  EOT

  query = "avg(last_10m):avg:kubernetes.filesystem.usage_pct{cluster_name:${var.cluster_name}} by {node} > 90"

  monitor_thresholds {
    critical = 90
    warning  = 80
  }

  tags = ["env:${var.environment}", "cluster:${var.cluster_name}"]
}

resource "datadog_dashboard_json" "aks_overview" {
  dashboard = templatefile("${path.module}/dashboards/aks-overview.json.tpl", {
    cluster_name = var.cluster_name
    environment  = var.environment
  })
}
