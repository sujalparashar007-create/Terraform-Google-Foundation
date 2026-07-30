# ==============================================================================
# MODULE: finops-budget-controls — outputs
# ==============================================================================

output "scoped_budget_ids" {
  description = "Map of scope key to budget resource name"
  value       = { for k, v in google_billing_budget.scoped : k => v.name }
}
