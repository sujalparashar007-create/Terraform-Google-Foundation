# ==============================================================================
# MODULE: org-policy — Hierarchical Firewall Policy
# ==============================================================================
# Creates a global compute firewall policy with rules and attaches it to
# the GCP organization. All descendant projects / VPCs inherit these rules.
# ==============================================================================

resource "google_compute_firewall_policy" "foundation" {
  short_name  = "fp-${var.project_prefix}-foundation"
  parent      = "organizations/${var.org_id}"
  description = "Foundation-wide hierarchical firewall policy"
}

resource "google_compute_firewall_policy_rule" "rules" {
  for_each = { for idx, rule in var.rules : idx => rule }

  firewall_policy = google_compute_firewall_policy.foundation.id
  priority        = each.value.priority
  direction       = "INGRESS"
  action          = each.value.action
  enable_logging  = false

  match {
    src_ip_ranges = [each.value.src_range]
    layer4_configs {
      ip_protocol = "tcp"
      ports       = each.value.ports
    }
  }

  description = each.value.description
}

resource "google_compute_firewall_policy_association" "org" {
  name              = "fp-${var.project_prefix}-foundation-association"
  attachment_target = "organizations/${var.org_id}"
  firewall_policy   = google_compute_firewall_policy.foundation.id
}
