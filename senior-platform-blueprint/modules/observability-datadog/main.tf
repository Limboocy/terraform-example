# Observability as code for one AKS cluster: Datadog monitors, an SLO, and a
# dashboard. Thresholds are parameterized (per-env tuning) and every metric
# monitor sets evaluation_delay so late-arriving Kubernetes metrics don't page
# on false positives.

locals {
  base_tags   = ["env:${var.environment}", "cluster:${var.cluster_name}", "managed_by:terraform"]
  alert_route = "@slack-${var.alert_channel}${var.pagerduty_service != null ? " @pagerduty-${var.pagerduty_service}" : ""}"
}

resource "datadog_monitor" "node_cpu_high" {
  name    = "[${var.environment}] AKS node CPU > ${var.cpu_critical}%"
  type    = "metric alert"
  message = <<-EOT
    {{#is_alert}}
    Node CPU on ${var.cluster_name} is above ${var.cpu_critical}%.
    Runbook: ${var.runbook_url}
    ${local.alert_route}
    {{/is_alert}}
    {{#is_recovery}}
    Node CPU on ${var.cluster_name} recovered.
    {{/is_recovery}}
  EOT

  query = "avg(last_5m):avg:kubernetes.cpu.usage.total{cluster_name:${var.cluster_name}} by {node} > ${var.cpu_critical}"

  monitor_thresholds {
    critical = var.cpu_critical
    warning  = var.cpu_warning
  }

  # Kubernetes/DD metrics lag; evaluate 60s in the past to avoid false pages.
  evaluation_delay    = 60
  notify_no_data      = true
  no_data_timeframe   = 20
  renotify_interval   = var.renotify_interval
  priority            = var.priority
  require_full_window = false

  tags = local.base_tags
}

resource "datadog_monitor" "pod_crashloop" {
  name    = "[${var.environment}] Pod CrashLoopBackOff on ${var.cluster_name}"
  type    = "event-v2 alert"
  message = <<-EOT
    {{#is_alert}}
    Pods are crash-looping on ${var.cluster_name}.
    Runbook: ${var.runbook_url}
    ${local.alert_route}
    {{/is_alert}}
  EOT

  query = "events(\"sources:kubernetes \\\"CrashLoopBackOff\\\" cluster_name:${var.cluster_name}\").rollup(\"count\").last(\"5m\") > ${var.crashloop_threshold}"

  renotify_interval = var.renotify_interval
  priority          = var.priority
  tags              = local.base_tags
}

resource "datadog_monitor" "node_disk_pressure" {
  name    = "[${var.environment}] Node disk pressure on ${var.cluster_name}"
  type    = "metric alert"
  message = <<-EOT
    {{#is_alert}}
    Node filesystem usage on ${var.cluster_name} is critical.
    Runbook: ${var.runbook_url}
    ${local.alert_route}
    {{/is_alert}}
  EOT

  query = "avg(last_10m):avg:kubernetes.filesystem.usage_pct{cluster_name:${var.cluster_name}} by {node} > ${var.disk_critical}"

  monitor_thresholds {
    critical = var.disk_critical
    warning  = var.disk_warning
  }

  evaluation_delay    = 60
  renotify_interval   = var.renotify_interval
  priority            = var.priority
  require_full_window = false
  tags                = local.base_tags
}

# Availability SLO built on the CrashLoop + a synthetic uptime monitor would be
# ideal; here we track a metric-based SLO on pod readiness as a learning example.
resource "datadog_service_level_objective" "pod_availability" {
  name        = "[${var.environment}] ${var.cluster_name} pod availability"
  type        = "monitor"
  description = "Target availability for application pods."

  monitor_ids = [datadog_monitor.pod_crashloop.id]

  thresholds {
    timeframe = "30d"
    target    = var.slo_target
    warning   = var.slo_warning
  }

  tags = local.base_tags
}

resource "datadog_dashboard_json" "aks_overview" {
  dashboard = templatefile("${path.module}/dashboards/aks-overview.json.tpl", {
    cluster_name = var.cluster_name
    environment  = var.environment
  })
}
