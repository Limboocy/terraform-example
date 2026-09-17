variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "retention_in_days" {
  type        = number
  description = "Log retention. Longer in prod for incident/compliance review."
  default     = 30

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 30 and 730."
  }
}

variable "daily_quota_gb" {
  type        = number
  description = "Daily ingestion cap in GB. -1 = unlimited (avoid in non-prod)."
  default     = 5
}

variable "tags" {
  type    = map(string)
  default = {}
}
