variable "project" {
  type = string
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Prevents permanent deletion of the vault for the soft-delete retention period. Required in prod."
  default     = false
}

variable "soft_delete_retention_days" {
  type    = number
  default = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "workload_identity_object_id" {
  type        = string
  description = "Object ID of the managed identity that app pods use to read secrets. Null = no assignment."
  default     = null
}

variable "private_endpoint_enabled" {
  type        = bool
  description = "Wire a private endpoint so vault traffic stays inside the VNet."
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The private-endpoints subnet ID. Required when private_endpoint_enabled = true."
  default     = null
}

variable "vnet_id" {
  type        = string
  description = "VNet to link the private DNS zone to. Required when private_endpoint_enabled = true."
  default     = null
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "IP ranges allowed to reach the vault when private_endpoint_enabled = false (dev)."
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
