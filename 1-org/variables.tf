# ------------------------------------------------------------------------------
# Organization inputs
# ------------------------------------------------------------------------------

variable "org_id" {
  description = "GCP Organization ID (numeric)"
  type        = string
}

variable "project_prefix" {
  description = "Prefix used across all project names in the foundation"
  type        = string
  default     = "foundation"
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "us-east1"
}

# ------------------------------------------------------------------------------
# Org-level IAM bindings — parameterized map
# ------------------------------------------------------------------------------

variable "org_iam_bindings" {
  description = "Map of org-level IAM bindings (role → member)"
  type = map(object({
    role   = string
    member = string
  }))
  default = {}
}

# ------------------------------------------------------------------------------
# Firewall rule CIDR overrides
# ------------------------------------------------------------------------------

variable "corp_ssh_range" {
  description = "Corporate SSH source CIDR"
  type        = string
  default     = "198.51.100.0/24"
}

variable "vpn_ssh_range" {
  description = "VPN SSH source CIDR"
  type        = string
  default     = "198.51.101.0/24"
}

variable "bastion_range" {
  description = "Bastion host source CIDR"
  type        = string
  default     = "10.10.10.0/24"
}

variable "vuln_scanner_range" {
  description = "Vulnerability scanner source CIDR"
  type        = string
  default     = "10.20.0.0/24"
}

variable "monitoring_range" {
  description = "Monitoring collector source CIDR"
  type        = string
  default     = "10.30.0.0/24"
}

variable "backup_range" {
  description = "Backup service source CIDR"
  type        = string
  default     = "10.40.0.0/24"
}

# ------------------------------------------------------------------------------
# Computed locals
# ------------------------------------------------------------------------------

locals {
  firewall_rules = [
    {
      priority    = 200
      action      = "allow"
      src_range   = var.corp_ssh_range
      ports       = ["22"]
      description = "Allow enterprise SSH from corporate range"
    },
    {
      priority    = 300
      action      = "allow"
      src_range   = var.vpn_ssh_range
      ports       = ["22"]
      description = "Allow enterprise SSH from VPN range"
    },
    {
      priority    = 400
      action      = "allow"
      src_range   = var.bastion_range
      ports       = ["22"]
      description = "Allow enterprise SSH from bastion range"
    },
    {
      priority    = 500
      action      = "allow"
      src_range   = var.vuln_scanner_range
      ports       = ["443", "9100"]
      description = "Allow vulnerability scanner"
    },
    {
      priority    = 600
      action      = "allow"
      src_range   = var.monitoring_range
      ports       = ["9090"]
      description = "Allow monitoring collector"
    },
    {
      priority    = 700
      action      = "allow"
      src_range   = var.backup_range
      ports       = ["8443"]
      description = "Allow backup service"
    },
  ]
}
