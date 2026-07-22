variable "org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "billing_account" {
  description = "Billing Account ID"
  type        = string
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
