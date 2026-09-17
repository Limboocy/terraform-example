variable "resource_group_id" {
  type        = string
  description = "Scope the tag policies apply to."
}

variable "required_tags" {
  type        = list(string)
  description = "Tag keys that must be present on resources."
  default     = ["project", "environment", "managed_by", "cost_center"]
}
