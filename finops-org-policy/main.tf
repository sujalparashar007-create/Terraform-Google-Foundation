# ==============================================================================
# MODULE: finops-org-policy — Hierarchical Firewall Policy for FinOps
# ==============================================================================
# Creates organization-level hierarchical firewall policies that are
# automatically inherited by ALL projects (including finops VPCs).
#
# Rules are declared declaratively via var.rules — just add a map entry.
# No need to touch main.tf when adding/removing rules.
#
# Usage:
#   module "finops_org_policy" {
#     source = "../finops-org-policy"
#     org_id = "123456789"
#     rules = {
#       allow_monitoring = {
#         priority    = 100
#         action      = "allow"
#         direction   = "INGRESS"
#         src_ranges  = ["10.100.0.0/16"]
#         ports       = ["9090"]
#         description = "Allow FinOps monitoring collector"
#       }
#     }
#   }
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. HIERARCHICAL FIREWALL POLICY (org-level)
# ------------------------------------------------------------------------------
resource "google_compute_firewall_policy" "finops" {
  short_name  = "fp-finops-${var.policy_suffix}"
  parent      = "organizations/${var.org_id}"
  description = "FinOps hierarchical firewall policy — inherited by all projects"
}

# ------------------------------------------------------------------------------
# 2. FIREWALL RULES (declarative — add/remove from var.rules only)
# ------------------------------------------------------------------------------
resource "google_compute_firewall_policy_rule" "rules" {
  for_each = var.rules

  firewall_policy = google_compute_firewall_policy.finops.id
  priority        = each.value.priority
  direction       = each.value.direction
  action          = each.value.action
  enable_logging  = each.value.enable_logging

  match {
    src_ip_ranges = each.value.src_ranges
    layer4_configs {
      ip_protocol = "tcp"
      ports       = each.value.ports
    }
  }

  description = each.value.description
}

# ------------------------------------------------------------------------------
# 3. ORG ASSOCIATION — attach policy to organization
# ------------------------------------------------------------------------------
resource "google_compute_firewall_policy_association" "org" {
  name              = "fp-finops-${var.policy_suffix}-association"
  attachment_target = "organizations/${var.org_id}"
  firewall_policy   = google_compute_firewall_policy.finops.id
}
