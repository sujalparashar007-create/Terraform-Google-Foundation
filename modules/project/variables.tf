# ==============================================================================
# MODULE: project — variables
# ==============================================================================

variable "name" {
  description = "Display name for the project"
  type        = string
}

variable "project_id" {
  description = "Globally unique project ID (cannot be changed after creation)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID (6-30 chars, lowercase letters, digits, hyphens)."
  }
}

variable "org_id" {
  description = "GCP Organization ID (numeric)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.org_id))
    error_message = "org_id must be numeric (e.g. 123456789)."
  }
}

variable "billing_account" {
  description = "GCP Billing Account ID (format: XXXXXX-XXXXXX-XXXXXX)"
  type        = string

  validation {
    condition     = can(regex("^[A-F0-9]{6}-[A-F0-9]{6}-[A-F0-9]{6}$", var.billing_account))
    error_message = "billing_account must match pattern XXXXXX-XXXXXX-XXXXXX."
  }
}

variable "folder_id" {
  description = "Numeric folder ID to place the project in (empty = org root)"
  type        = string
  default     = ""
}

variable "auto_create_network" {
  description = "Whether to auto-create the default VPC network"
  type        = bool
  default     = false
}

variable "activate_apis" {
  description = "List of GCP APIs to enable on the project"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to the project"
  type        = map(string)
  default     = {}
}
