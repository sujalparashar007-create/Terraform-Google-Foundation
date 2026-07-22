# ==============================================================================
# 3-HOST-PROJECTS — variables
# ==============================================================================

variable "org_id" {
  description = "GCP Organization ID (numeric)"
  type        = string
}

variable "billing_account" {
  description = "GCP Billing Account ID (format: XXXXXX-XXXXXX-XXXXXX)"
  type        = string
}

variable "project_prefix" {
  description = "Prefix used across all project IDs in the foundation"
  type        = string
  default     = "foundation"
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "us-east1"
}

# ------------------------------------------------------------------------------
# Host project API overrides (optional)
# ------------------------------------------------------------------------------
# Each host project gets a sensible default set of APIs. Override per host key
# if you need extras (or fewer) for a specific environment.
# Keys: hub, dev

variable "host_project_apis" {
  description = "Override default APIs per host project key (hub/dev)"
  type        = map(list(string))
  default     = {}
}
