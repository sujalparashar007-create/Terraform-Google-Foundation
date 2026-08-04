output "rule_ids" {
  description = "Map of firewall rule IDs"
  value       = { for k, v in google_compute_firewall.firewall_rules : k => v.id }
}
