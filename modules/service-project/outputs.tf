output "project_id" {
  description = "Service project ID"
  value       = module.project.project_id
}

output "project_number" {
  description = "Service project number"
  value       = module.project.project_number
}

output "compute_sa_email" {
  description = "Compute engine default service account email"
  value       = google_service_account.compute_sa.email
}

output "subnet_self_link" {
  description = "Subnet self-link (passthrough)"
  value       = var.subnet_self_link
}
