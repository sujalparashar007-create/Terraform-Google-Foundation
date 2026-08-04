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
  description = "Default GCP region"
  type        = string
  default     = "us-east1"
}
variable "connectivity_model" {
  description = "Connectivity model: peering or ncc"
  type        = string
  default     = "peering"
  validation {
    condition     = contains(["peering", "ncc"], var.connectivity_model)
    error_message = "Must be peering or ncc"
  }
}
variable "egress_model" {
  description = "Egress model: distributed_nat or centralized_inspection"
  type        = string
  default     = "distributed_nat"
  validation {
    condition     = contains(["distributed_nat", "centralized_inspection"], var.egress_model)
    error_message = "Must be distributed_nat or centralized_inspection"
  }
}
variable "shared_vpc_enabled" {
  description = "Enable Shared VPC"
  type        = bool
  default     = true
}
variable "hub_cidr" {
  description = "Hub CIDR block"
  type        = string
  default     = "10.0.0.0/20"
}
variable "hub_subnet_cidr" {
  description = "Hub primary subnet"
  type        = string
  default     = "10.0.0.0/24"
}
variable "environments" {
  description = "Map of environments to deploy (dev only for now)"
  type = map(object({
    spoke_cidr    = string
    subnet_cidr   = string
    workload_type = string
    vpc_name      = string
    subnet_name   = string
    nat_enabled   = optional(bool, true)
    pod_cidr      = optional(string, "")
    svc_cidr      = optional(string, "")
  }))
  default = {
    dev = {
      spoke_cidr    = "10.16.0.0/16"
      subnet_cidr   = "10.16.0.0/22"
      workload_type = "vm"
      vpc_name      = "vpc-dev-spoke"
      subnet_name   = "sb-dev-vm-us-east1"
      nat_enabled   = true
    }
  }
}
