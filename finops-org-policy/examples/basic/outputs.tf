output "policy_id" {
  description = "Full resource ID of the hierarchical firewall policy"
  value       = module.finops_org_policy.policy_id
}

output "policy_name" {
  description = "Short name of the firewall policy"
  value       = module.finops_org_policy.policy_name
}
