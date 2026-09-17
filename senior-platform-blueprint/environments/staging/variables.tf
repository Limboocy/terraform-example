variable "project" {
  type    = string
  default = "aksplatform"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "cost_center" {
  type = string
}

variable "owner" {
  type    = string
  default = "platform-engineering"
}

variable "aks_admin_group_object_ids" {
  type = list(string)
}

variable "budget_start_date" {
  type    = string
  default = "2026-01-01T00:00:00Z"
}

variable "cost_alert_emails" {
  type    = list(string)
  default = []
}
