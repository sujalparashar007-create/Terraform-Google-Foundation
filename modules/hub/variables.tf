# ==============================================================================
# MODULE: hub — variables
# ==============================================================================

variable "project_id" {
  description = "GCP project ID where the hub VPC will be created"
  type        = string
}

variable "region" {
  description = "Default GCP region for the hub"
  type        = string
}

variable "hub_cidr" {
  description = "CIDR block reserved for the hub (e.g. 10.0.0.0/20)"
  type        = string
  default     = "10.0.0.0/20"
}

variable "subnet_cidr" {
  description = "Primary hub subnet CIDR (first /24 carved from hub_cidr)"
  type        = string
  default     = "10.0.0.0/24"
}

variable "subnet_name" {
  description = "Name for the hub subnet"
  type        = string
  default     = "sb-hub"
}

variable "vpc_name" {
  description = "Name for the hub VPC"
  type        = string
  default     = "vpc-hub"
}

variable "router_name" {
  description = "Name for the Cloud Router"
  type        = string
  default     = "cr-hub"
}

variable "router_asn" {
  description = "BGP ASN for the Cloud Router"
  type        = number
  default     = 64514
}
