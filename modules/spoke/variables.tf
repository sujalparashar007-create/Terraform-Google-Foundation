variable "project_id" {
  description = "GCP project ID for the spoke VPC"
  type        = string
}
variable "region" {
  description = "GCP region"
  type        = string
}
variable "env_name" {
  description = "Environment name (dev/nonprod/prod)"
  type        = string
}
variable "spoke_cidr" {
  description = "CIDR block for the spoke (e.g. 10.16.0.0/16)"
  type        = string
}
variable "vpc_name" {
  description = "Name for the spoke VPC"
  type        = string
}
variable "subnet_name" {
  description = "Name for the primary subnet"
  type        = string
}
variable "subnet_cidr" {
  description = "CIDR for the primary subnet"
  type        = string
}
variable "workload_type" {
  description = "Workload type: vm / gke / mixed"
  type        = string
  default     = "vm"
  validation {
    condition     = contains(["vm", "gke", "mixed"], var.workload_type)
    error_message = "workload_type must be vm, gke, or mixed"
  }
}
variable "pod_cidr" {
  description = "GKE pod secondary range CIDR"
  type        = string
  default     = ""
}
variable "svc_cidr" {
  description = "GKE services secondary range CIDR"
  type        = string
  default     = ""
}
