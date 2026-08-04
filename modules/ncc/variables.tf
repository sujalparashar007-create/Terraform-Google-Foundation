# ==============================================================================
# MODULE: ncc - Network Connectivity Center hub-and-spoke
# ==============================================================================
# Variables for the NCC module that creates a central hub and VPC spokes
# to enable full-mesh connectivity across all attached VPCs without peering.
# ==============================================================================

variable "hub_project_id" {
  description = "GCP project ID where the NCC hub will be created"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.hub_project_id))
    error_message = "hub_project_id must be a valid GCP project ID (6-30 chars, lowercase letters, digits, hyphens)."
  }
}

variable "hub_name" {
  description = "Name for the NCC hub"
  type        = string
  default     = "ncc-hub"
}

variable "region" {
  description = "GCP region (used for resource labels only; NCC hub and VPC spokes are global)"
  type        = string
}

variable "vpc_spokes" {
  description = "Map of spoke name -> {project_id, vpc_self_link} to attach to the NCC hub"
  type = map(object({
    project_id    = string
    vpc_self_link = string
  }))
}

variable "labels" {
  description = "Labels to apply to NCC resources"
  type        = map(string)
  default     = {}
}
