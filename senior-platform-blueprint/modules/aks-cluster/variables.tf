variable "project" {
  type        = string
  description = "Short project/product slug used in resource names."
}

variable "environment" {
  type        = string
  description = "Deployment environment."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region, e.g. eastus."
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Subnet the node pools attach to (Azure CNI)."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Workspace for OMS agent, Defender, and diagnostics."
}

variable "kubernetes_version" {
  type        = string
  description = "Control-plane minor version. Pinned; patches applied via automatic_channel_upgrade."
  default     = "1.29"
}

variable "sku_tier" {
  type        = string
  description = "Control-plane SLA tier. Free (no SLA) only for dev."
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be Free, Standard, or Premium."
  }
}

variable "automatic_channel_upgrade" {
  type        = string
  description = "AKS auto-upgrade channel: patch, stable, rapid, node-image, or none."
  default     = "patch"

  validation {
    condition     = contains(["patch", "stable", "rapid", "node-image", "none"], var.automatic_channel_upgrade)
    error_message = "Invalid automatic_channel_upgrade value."
  }
}

variable "private_cluster_enabled" {
  type        = bool
  description = "If true, API server is private (no public endpoint)."
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "CIDRs allowed to reach a public API server. Only used when private_cluster_enabled = false."
  default     = []
}

variable "local_account_disabled" {
  type        = bool
  description = "Disable the local admin kubeconfig. Should be true everywhere except break-glass dev."
  default     = true
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "Entra ID group object IDs granted cluster-admin via Azure RBAC."

  validation {
    condition     = length(var.admin_group_object_ids) > 0
    error_message = "At least one admin group object ID is required — the cluster must be reachable by someone."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "AZs to spread node pools across. Use [] for single-zone regions."
  default     = ["1", "2", "3"]
}

variable "outbound_type" {
  type        = string
  description = "Egress model: loadBalancer or userDefinedRouting."
  default     = "loadBalancer"
}

variable "max_pods" {
  type    = number
  default = 50
}

variable "os_disk_size_gb" {
  type    = number
  default = 128
}

# --- Node pool sizing ---

variable "system_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "system_min_count" {
  type    = number
  default = 1
}

variable "system_max_count" {
  type    = number
  default = 3
}

variable "app_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "app_min_count" {
  type    = number
  default = 2
}

variable "app_max_count" {
  type    = number
  default = 10
}

variable "app_node_taints" {
  type        = list(string)
  description = "Taints applied to the app pool, e.g. [\"workload=app:NoSchedule\"]."
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
