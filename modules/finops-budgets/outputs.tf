output "budget_ids" {
  description = "Map of budget key to resource name"
  value       = { for k, v in google_billing_budget.budget : k => v.name }
}

output "budget_names" {
  description = "Map of budget key to display name"
  value       = { for k, v in google_billing_budget.budget : k => v.display_name }
}

output "finops_budgets_view_id" {
  description = "Fully qualified finops_budgets view ID for Module 5"
  value       = var.project_id != "" ? "${var.project_id}.${var.dataset_id}.finops_budgets" : null
}
