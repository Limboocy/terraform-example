variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "alert_channel" {
  type        = string
  description = "Slack channel name (without #) to route alerts to"
  default     = "devops-alerts"
}
