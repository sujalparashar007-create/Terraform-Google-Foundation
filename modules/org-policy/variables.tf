variable "org_id" {
  description = "GCP Organization ID (numeric)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.org_id))
    error_message = "org_id must be numeric (e.g. 123456789)."
  }
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
