# ==============================================================================
# MODULE: project — outputs
# ==============================================================================

output "project_id" {
  description = "Globally unique project ID"
  value       = google_project.project.project_id
}

output "project_number" {
  description = "Numeric project number (auto-assigned by GCP)"
  value       = google_project.project.number
}

output "project_name" {
  description = "Display name of the project"
  value       = google_project.project.name
}
