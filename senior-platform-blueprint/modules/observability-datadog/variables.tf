variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "alert_channel" {
  type        = string
  description = "Slack channel (without the leading @slack-) for alerts."
}

variable "pagerduty_service" {
  type        = string
  description = "Optional PagerDuty service handle for prod paging. Null = Slack only."
  default     = null
}

variable "runbook_url" {
  type        = string
  description = "Link included in every alert so on-call has an immediate next step."
  default     = "https://runbooks.internal/aks"
}

# --- Thresholds (per-env tunable) ---

variable "cpu_critical" {
  type    = number
  default = 85
}

variable "cpu_warning" {
  type    = number
  default = 70
}

variable "disk_critical" {
  type    = number
  default = 90
}

variable "disk_warning" {
  type    = number
  default = 80
}

variable "crashloop_threshold" {
  type    = number
  default = 3
}

# --- Alerting behaviour ---

variable "renotify_interval" {
  type        = number
  description = "Minutes before re-alerting on a still-open incident. 0 = never."
  default     = 30
}

variable "priority" {
  type        = number
  description = "Datadog monitor priority 1 (highest) - 5."
  default     = 3

  validation {
    condition     = var.priority >= 1 && var.priority <= 5
    error_message = "priority must be between 1 and 5."
  }
}

# --- SLO ---

variable "slo_target" {
  type    = number
  default = 99.9
}

variable "slo_warning" {
  type    = number
  default = 99.95
}
