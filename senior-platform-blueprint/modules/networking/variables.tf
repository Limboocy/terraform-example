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

variable "vnet_cidr" {
  type = string

  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "vnet_cidr must be a valid CIDR block."
  }
}

variable "aks_subnet_cidr" {
  type = string

  validation {
    condition     = can(cidrhost(var.aks_subnet_cidr, 0))
    error_message = "aks_subnet_cidr must be a valid CIDR block."
  }
}

variable "pe_subnet_cidr" {
  type = string

  validation {
    condition     = can(cidrhost(var.pe_subnet_cidr, 0))
    error_message = "pe_subnet_cidr must be a valid CIDR block."
  }
}

variable "extra_inbound_rules" {
  description = "Environment-specific allow rules layered above the deny-all default."
  type = list(object({
    name                   = string
    priority               = number
    access                 = string
    protocol               = string
    destination_port_range = string
    source_address_prefix  = string
  }))
  default = []
}

# --- Flow logs (optional; wired in staging/prod) ---

variable "enable_flow_logs" {
  type    = bool
  default = false
}

variable "network_watcher_name" {
  type    = string
  default = null
}

variable "network_watcher_resource_group" {
  type    = string
  default = null
}

variable "flow_log_storage_account_id" {
  type    = string
  default = null
}

variable "flow_log_retention_days" {
  type    = number
  default = 90
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "log_analytics_workspace_guid" {
  description = "The workspace GUID (workspace_id attribute), not the ARM resource ID."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
