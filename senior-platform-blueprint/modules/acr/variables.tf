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

variable "kubelet_identity_object_id" {
  type        = string
  description = "AKS kubelet managed identity object ID. Granted AcrPull so nodes can pull images."
}

variable "sku" {
  type        = string
  description = "Basic/Standard for dev (no private endpoint). Premium required for private endpoints."
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "Zone-redundant storage for the registry. Premium SKU only."
  default     = false
}

variable "private_endpoint_enabled" {
  type        = bool
  description = "Wire a private endpoint so registry traffic stays inside the VNet."
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

variable "tags" {
  type    = map(string)
  default = {}
}
