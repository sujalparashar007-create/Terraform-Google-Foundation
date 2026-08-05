# ==============================================================================
# MODULE: finops-org-policy — variables
# ==============================================================================

# --- REQUIRED ---

variable "org_id" {
  description = "GCP Organization ID (numeric)"
  type        = string
}

# --- OPTIONAL ---

variable "policy_suffix" {
  description = "Suffix for policy short name (keep short — max ~15 chars)"
  type        = string
  default     = "foundation"
}

variable "rules" {
  description = "Map of hierarchical firewall rules. Add/remove entries to change policy."
  type = map(object({
    priority       = number
    action         = string
    direction      = optional(string, "INGRESS")
    src_ranges     = list(string)
    ports          = list(string)
    description    = string
    enable_logging = optional(bool, false)
  }))
  default = {}
}
