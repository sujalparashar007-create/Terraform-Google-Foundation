# ==============================================================================
# 0-BOOTSTRAP — Platform Wrapper
# ==============================================================================
# Creates:
#   1. Seed project (hosts the state bucket + Terraform SA)
#   2. Required APIs enabled on the seed project
#   3. Terraform CI/CD service account + minimal org-level IAM roles
#   4. GCS state bucket (versioned, uniform bucket-level access)
#   5. SA impersonation wiring for downstream stages
#
# Outputs (consumed by every later stage):
#   - terraform_sa_email   -> provider alias impersonation in downstream stages
#   - state_bucket_name    -> backend "gcs" block in every downstream stage
#   - seed_project_id      -> reference for debugging / audit
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. SEED PROJECT
# ------------------------------------------------------------------------------
resource "google_project" "seed" {
  name                = var.seed_project_name
  project_id          = "${var.project_prefix}-bootstrap-seed"
  org_id              = var.org_id
  billing_account     = var.billing_account
  auto_create_network = false

  # Prevent accidental destruction
  lifecycle {
    prevent_destroy = true
  }
}

# ------------------------------------------------------------------------------
# 2. ENABLE REQUIRED APIs (on the seed project)
# ------------------------------------------------------------------------------
# These APIs are needed by the seed project itself and by the Terraform SA when
# it manages resources across the org (project creation, networking, IAM, etc.)

locals {
  seed_apis = [
    "cloudresourcemanager.googleapis.com", # Org / folder / project CRUD
    "compute.googleapis.com",              # VPC, subnets, NAT, firewalls
    "iam.googleapis.com",                  # Service accounts + IAM bindings
    "serviceusage.googleapis.com",         # Enable APIs on child projects
    "dns.googleapis.com",                  # Cloud DNS (hub DNS forwarding)
    "storage.googleapis.com",              # GCS state bucket
    "cloudbilling.googleapis.com",         # Billing account management
    "iamcredentials.googleapis.com",       # SA impersonation / token exchange
  ]
}

resource "google_project_service" "seed_apis" {
  for_each = toset(local.seed_apis)

  project = google_project.seed.project_id
  service = each.key

  # Don't disable on destroy — other resources in the project may need them
  disable_on_destroy = false
}

# ------------------------------------------------------------------------------
# 3. TERRAFORM SERVICE ACCOUNT
# ------------------------------------------------------------------------------
resource "google_service_account" "terraform_sa" {
  account_id   = "tf-executor"
  display_name = "Terraform CI/CD Executor (bootstrap)"
  project      = google_project.seed.project_id

  depends_on = [google_project_service.seed_apis]
}

# ------------------------------------------------------------------------------
# 4. ORG-LEVEL IAM ROLES (minimal required set)
# ------------------------------------------------------------------------------
# These roles allow the Terraform SA to create folders, projects, and manage
# networking / IAM across the entire organization.

# Allows creating projects under the organization
resource "google_organization_iam_member" "project_creator" {
  org_id = var.org_id
  role   = "roles/resourcemanager.projectCreator"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Allows creating folders under the organization
resource "google_organization_iam_member" "folder_creator" {
  org_id = var.org_id
  role   = "roles/resourcemanager.folderCreator"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Allows viewing org metadata (folder structure, policies)
resource "google_organization_iam_member" "org_viewer" {
  org_id = var.org_id
  role   = "roles/resourcemanager.organizationViewer"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Allows granting IAM roles on projects the SA creates (Owner-like)


# Allows creating/managing service accounts in child projects
resource "google_organization_iam_member" "sa_admin" {
  org_id = var.org_id
  role   = "roles/iam.serviceAccountAdmin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Allows managing IAM policies on child projects
resource "google_organization_iam_member" "security_admin" {
  org_id = var.org_id
  role   = "roles/iam.securityAdmin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Allows enabling APIs on child projects
resource "google_organization_iam_member" "service_usage_admin" {
  org_id = var.org_id
  role   = "roles/serviceusage.serviceUsageAdmin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Allows creating/managing hierarchical firewall policies (org-level)
resource "google_organization_iam_member" "firewall_policy_admin" {
  org_id = var.org_id
  role   = "roles/compute.orgFirewallPolicyAdmin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Allows attaching firewall policies to the organization
resource "google_organization_iam_member" "org_security_resource_admin" {
  org_id = var.org_id
  role   = "roles/compute.orgSecurityResourceAdmin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# --- Billing account level ---
# Allows linking created projects to the billing account
resource "google_billing_account_iam_member" "billing_user" {
  billing_account_id = var.billing_account
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# ------------------------------------------------------------------------------
# 5. GCS STATE BUCKET
# ------------------------------------------------------------------------------
resource "google_storage_bucket" "state_bucket" {
  name     = "${var.project_prefix}-tf-state-bootstrap"
  project  = google_project.seed.project_id
  location = var.region

  # Best practices for Terraform state storage
  # Best practices for Terraform state storage
  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Soft delete / retention
  soft_delete_policy {
    retention_duration_seconds = 604800 # 7 days
  }

  depends_on = [google_project_service.seed_apis]
}

# Grant the Terraform SA full access to its own state bucket
resource "google_storage_bucket_iam_member" "sa_bucket_admin" {
  bucket = google_storage_bucket.state_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# ------------------------------------------------------------------------------
# 6. SA IMPERSONATION — Let human operators + CI pipelines act AS the Terraform SA
# ------------------------------------------------------------------------------
# Human operators listed in var.terraform_operators can impersonate the SA locally:
#   gcloud auth application-default login --impersonate-service-account <terraform_sa_email>
#
# For CI pipelines, use Workload Identity Federation instead of static SA keys.

# Grant each human operator the ability to generate OAuth tokens for the SA
resource "google_service_account_iam_member" "impersonation" {
  for_each = toset(var.terraform_operators)

  service_account_id = google_service_account.terraform_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:${each.key}"
}
