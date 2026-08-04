variable "hub_vpc_self_link" {
  description = "Self-link of the hub VPC"
  type        = string

  validation {
    condition     = can(regex("^https://www\\.googleapis\\.com/compute/", var.hub_vpc_self_link))
    error_message = "hub_vpc_self_link must be a valid GCP VPC self-link."
  }
}
variable "spoke_vpc_self_link" {
  description = "Self-link of the spoke VPC"
  type        = string

  validation {
    condition     = can(regex("^https://www\\.googleapis\\.com/compute/", var.spoke_vpc_self_link))
    error_message = "spoke_vpc_self_link must be a valid GCP VPC self-link."
  }
}
variable "env_name" {
  description = "Environment name for naming the peering"
  type        = string
}
variable "export_custom_routes" {
  description = "Export custom routes from this side"
  type        = bool
  default     = false
}
variable "import_custom_routes" {
  description = "Import custom routes to this side"
  type        = bool
  default     = false
}
