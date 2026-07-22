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
}

variable "org_id" {
  description = "GCP Organization ID (numeric)"
  type        = string
}

variable "billing_account" {
  description = "GCP Billing Account ID (format: XXXXXX-XXXXXX-XXXXXX)"
  type        = string
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
