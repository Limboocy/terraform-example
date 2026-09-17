variable "project" {
  type        = string
  description = "Short project name, used in resource naming, e.g. 'trp'"
}

variable "environment" {
  type        = string
  description = "dev | staging | prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region, e.g. 'eastus'"
}

variable "vnet_cidr" {
  type        = string
  description = "CIDR block for the VNet"
}

variable "aks_subnet_cidr" {
  type        = string
  description = "CIDR block for the AKS node subnet"
}

variable "pe_subnet_cidr" {
  type        = string
  description = "CIDR block for private endpoints (e.g. Key Vault, ACR)"
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags"
  default     = {}
}
