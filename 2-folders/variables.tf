# ==============================================================================
# 2-FOLDERS — variables
# ==============================================================================

variable "org_id" {
  description = "GCP Organization ID (numeric)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.org_id))
    error_message = "org_id must be numeric (e.g. 123456789)."
  }
}

variable "project_prefix" {
  description = "Prefix used across all project names in the foundation"
  type        = string
  default     = "foundation"
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "us-east1"
}

# ------------------------------------------------------------------------------
# Folder-level IAM bindings
# ------------------------------------------------------------------------------
# Grant project creation rights to specific principals per folder.
# Example:
#   folder_iam_bindings = {
#     network_dev = {
#       folder_key = "fldr-network"
#       role       = "roles/resourcemanager.projectCreator"
#       member     = "group:network-admins@example.com"
#     }
#   }

variable "folder_iam_bindings" {
  description = "Map of folder-level IAM bindings. Key = binding id, value = { folder_key, role, member }"
  type = map(object({
    folder_key = string
    role       = string
    member     = string
  }))
  default = {}
}
