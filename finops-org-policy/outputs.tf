# ==============================================================================
# MODULE: finops-org-policy — outputs
# ==============================================================================

output "policy_id" {
  description = "Full resource ID of the hierarchical firewall policy"
  value       = google_compute_firewall_policy.finops.id
}

output "policy_name" {
  description = "Short name of the hierarchical firewall policy"
  value       = google_compute_firewall_policy.finops.short_name
}
