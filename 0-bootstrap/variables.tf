variable "org_id" {
  description = "GCP Organization ID (numeric)"
  type        = string
}

variable "billing_account" {
  description = "GCP Billing Account ID (format: XXXXXX-XXXXXX-XXXXXX)"
  type        = string
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
