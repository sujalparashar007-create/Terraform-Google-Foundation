# ──────────────────────────────────────────────────────────────────────────────
# 1-ORG — outputs
# ──────────────────────────────────────────────────────────────────────────────

output "org_policy_id" {
  description = "Full resource ID of the hierarchical firewall policy"
  value       = module.org_policy.policy_id
}
