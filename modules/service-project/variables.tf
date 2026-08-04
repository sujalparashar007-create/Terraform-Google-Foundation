variable "org_id" {
  description = "GCP Organization ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.org_id))
    error_message = "org_id must be numeric (e.g. 123456789)."
  }
}

variable "billing_account" {
  description = "Billing Account ID"
  type        = string

  validation {
    condition     = can(regex("^[A-F0-9]{6}-[A-F0-9]{6}-[A-F0-9]{6}$", var.billing_account))
    error_message = "billing_account must match pattern XXXXXX-XXXXXX-XXXXXX."
  }
}

variable "folder_id" {
  description = "Numeric folder ID to place the service project in"
  type        = string
}

variable "host_project_id" {
  description = "Project ID of the Shared VPC host (spoke host project)"
  type        = string
}

variable "service_project_name" {
  description = "Display name for the service project"
  type        = string
}

variable "service_project_id" {
  description = "Globally unique project ID for the service project"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.service_project_id))
    error_message = "service_project_id must be a valid GCP project ID (6-30 chars, lowercase letters, digits, hyphens)."
  }
}

variable "subnet_self_link" {
  description = "Self-link of the subnet in the host project to grant networkUser on"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"
}

variable "activate_apis" {
  description = "Additional APIs to enable on the service project"
  type        = list(string)
  default     = []
}
