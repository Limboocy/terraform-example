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

variable "subnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "For AKS diagnostic/monitoring integration (oms_agent)"
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

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

variable "tags" {
  type    = map(string)
  default = {}
}
