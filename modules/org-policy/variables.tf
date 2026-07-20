variable "org_id" {
  description = "GCP Organization ID (numeric)"
  type        = string
}

variable "project_prefix" {
  description = "Prefix used for resource naming"
  type        = string
}

variable "rules" {
  description = "List of hierarchical firewall rules"
  type = list(object({
    priority    = number
    action      = string
    src_range   = string
    ports       = list(string)
    description = string
  }))
}
