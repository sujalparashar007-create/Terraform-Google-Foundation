# ==============================================================================
# MODULE: project — Google Cloud Project Factory
# ==============================================================================
# Creates a GCP project + enables required APIs. Used by all stages that need
# to create projects — never inline project creation elsewhere (single source
# of truth).
#
# Usage example:
#   module "app_project" {
#     source = "../modules/project"
#
#     name            = "prj-my-app"
#     project_id      = "myco-my-app-abc123"
#     org_id          = "123456789"
#     billing_account = "01A325-ABCDEF-012345"
#     folder_id       = "987654321"  # from 2-folders output
#     activate_apis   = ["compute.googleapis.com", "dns.googleapis.com"]
#   }
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. PROJECT
# ------------------------------------------------------------------------------
resource "google_project" "project" {
  name                = var.name
  project_id          = var.project_id
  org_id              = var.folder_id == "" ? var.org_id : null
  folder_id           = var.folder_id == "" ? null : var.folder_id
  billing_account     = var.billing_account
  auto_create_network = var.auto_create_network
  deletion_policy     = "DELETE"
  labels              = var.labels
}

# ------------------------------------------------------------------------------
# 2. ENABLE APIs
# ------------------------------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset(var.activate_apis)

  project = google_project.project.project_id
  service = each.key

  disable_on_destroy = false
}
