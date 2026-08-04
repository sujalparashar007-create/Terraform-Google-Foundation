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

variable "project_prefix" {
  description = "Prefix for project names"
  type        = string
  default     = "foundation"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone for the VM"
  type        = string
  default     = "us-east1-b"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", var.zone))
    error_message = "zone must be a valid GCP zone (e.g. us-east1-b)."
  }
}

variable "vm_operators" {
  description = "List of users who can SSH into the VM via IAP"
  type        = list(string)
  default     = ["your-email@example.com"]
}