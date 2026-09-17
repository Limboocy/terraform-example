variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "monthly_budget" {
  type        = number
  description = "Monthly spend cap for the environment, in the billing currency."

  validation {
    condition     = var.monthly_budget > 0
    error_message = "monthly_budget must be positive."
  }
}

variable "budget_start_date" {
  type        = string
  description = "First-of-month start date, RFC3339, e.g. 2026-01-01T00:00:00Z."
}

variable "alert_emails" {
  type        = list(string)
  description = "Recipients for cost alerts."
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
