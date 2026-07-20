output "policy_id" {
  description = "The full resource ID of the hierarchical firewall policy"
  value       = google_compute_firewall_policy.foundation.id
}

output "policy_name" {
  description = "Short name of the hierarchical firewall policy"
  value       = google_compute_firewall_policy.foundation.short_name
}
