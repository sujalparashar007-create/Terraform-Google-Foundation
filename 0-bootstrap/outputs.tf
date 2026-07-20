# ──────────────────────────────────────────────────────────────────────────────
# 0-BOOTSTRAP — outputs consumed by every downstream stage's backend "gcs" block
# ──────────────────────────────────────────────────────────────────────────────

output "terraform_sa_email" {
  description = "Service account email used by Terraform (impersonated by all downstream stages)"
  value       = google_service_account.terraform_sa.email
}

output "state_bucket_name" {
  description = "GCS bucket name that holds Terraform state for every stage"
  value       = google_storage_bucket.state_bucket.name
}

output "seed_project_id" {
  description = "Project ID of the bootstrap seed project"
  value       = google_project.seed.project_id
}
