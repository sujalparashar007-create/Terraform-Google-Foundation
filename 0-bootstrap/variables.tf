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

variable "region" {
  description = "Default GCP region for the seed project"
  type        = string
  default     = "us-east1"
}

variable "project_prefix" {
  description = "Prefix used across all project names in the foundation (e.g. 'myco')"
  type        = string
  default     = "foundation"
}

variable "seed_project_name" {
  description = "Name for the seed/bootstrap project (hosts Terraform SA + state bucket)"
  type        = string
  default     = "prj-bootstrap-seed"
}

variable "terraform_operators" {
  description = "List of human user emails allowed to impersonate the Terraform SA"
  type        = list(string)
  default     = []
}
