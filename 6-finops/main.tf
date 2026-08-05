# ==============================================================================
# MODULE 5: Integration & Validation - FinOps Root Configuration
# ==============================================================================
# Orchestrates all FinOps modules (0-4), deploys them together, creates the
# final monthly_kpi_summary view that joins daily_cost with finops_budgets,
# and exposes outputs for Dashboard 1 / Looker Studio consumption.
#
# Validation: after terraform apply, query the KPI view to confirm end-to-end
# data flow - billing export -> SQL views -> budgets -> monthly KPI summary.
#
# NOTE: Before first apply, manually grant the Terraform SA billing.admin on
# the billing account via GCP Console:
#   Billing -> Account Management -> [billing_account_id] -> Permissions
#   Add: tf-executor@[project_id].iam.gserviceaccount.com
#   Role: Billing Account Administrator
#
# Set enable_alert_function to false in .tfvars to stop email & Teams alerts.
# ==============================================================================

# ------------------------------------------------------------------------------
# LOCALS: load budget configuration from YAML + define foundation IAM/APIs
# ------------------------------------------------------------------------------
locals {
  budget_config = yamldecode(file(var.budgets_yaml_path))

  apis = [
    "billingbudgets.googleapis.com",
    "pubsub.googleapis.com",
    "monitoring.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "eventarc.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
  ]

  foundation_iam = {
    "roles/bigquery.admin" = [
      "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com",
    ]
    "roles/pubsub.admin" = [
      "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com",
    ]
    "roles/monitoring.editor" = [
      "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com",
    ]
    "roles/storage.admin" = [
      "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com",
    ]
    "roles/cloudfunctions.admin" = [
      "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com",
    ]
    "roles/secretmanager.admin" = [
      "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com",
    ]
  }
}

# ==============================================================================
# STEP 1: Foundation — APIs (F13) + Project-level IAM (F7)
#         Delegated to the finops-foundation module so that API enablement and
#         project-IAM are never scattered or duplicated across resources.
# ==============================================================================

module "finops_foundation" {
  source = "../finops-foundation"

  project_id    = var.project_id
  activate_apis = local.apis
  iam           = local.foundation_iam
}

# ==============================================================================
# STEP 1.5: Service Account act-as permissions (SA-level, stays inline)
# ==============================================================================

data "google_project" "finops" {
  project_id = var.project_id
}

resource "google_service_account_iam_member" "tf_sa_act_as" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/tf-executor@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "appspot_sa_act_as" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.project_id}@appspot.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "compute_default_sa_act_as" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${data.google_project.finops.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

# ==============================================================================
# STEP 1.6: Billing Account IAM (billing-level, stays inline)
# ==============================================================================

# NOTE: This requires the TF SA to already have billing.admin (manual bootstrapping).
# Once granted manually, Terraform can manage it going forward.
resource "google_billing_account_iam_member" "tf_sa_billing_admin" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.admin"
  member             = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

# ==============================================================================
# STEP 3: Module 0 - BigQuery Dataset (depends on BigQuery IAM)
# ==============================================================================

module "finops_dataset" {
  source = "../finops-dataset"

  project_id = var.project_id
  dataset_id = var.dataset_id
  location   = var.dataset_location

  labels = var.labels

  iam = var.dataset_iam

  depends_on = [
    module.finops_foundation
  ]
}

# ==============================================================================
# STEP 4: Module 1 - SQL Reporting Views (depends on dataset)
# ==============================================================================

module "finops_views" {
  source = "../finops-views"

  project_id = module.finops_dataset.project_id
  dataset_id = module.finops_dataset.dataset_id

  billing_export_table_id = var.billing_export_table_id

  budget_targets = module.finops_budgets.budget_amounts

  depends_on = [
    module.finops_dataset,
    module.finops_budgets
  ]
}

# ==============================================================================
# STEP 5: Module 3 - Pub/Sub + Email Alert Channels (depends on APIs + IAM)
# ==============================================================================

module "finops_alerts" {
  source = "../finops-alerts"

  project_id   = module.finops_dataset.project_id
  topic_name   = var.topic_name
  alert_emails = var.alert_emails

  depends_on = [
    module.finops_foundation
  ]
}

# ==============================================================================
# STEP 6: Module 2 - Billing Budgets (depends on alerts + billingbudgets API)
# ==============================================================================

module "finops_budgets" {
  source = "../finops-budgets"

  billing_account          = var.billing_account_id
  pubsub_topic_id          = module.finops_alerts.pubsub_topic_id
  notification_channel_ids = module.finops_alerts.notification_channel_ids

  budgets = merge(
    local.budget_config.budgets,
    local.budget_config.budget_control_scopes,
  )

  iam_viewers = var.iam_viewers

  depends_on = [
    module.finops_foundation,
    google_billing_account_iam_member.tf_sa_billing_admin,
    module.finops_alerts
  ]
}

# ==============================================================================
# STEP 7: Cloud Function — Budget Alert Processor
# ==============================================================================
# Deployed via the dedicated finops-function module.

module "finops_function" {
  source = "../finops-function"

  project_id          = var.project_id
  region              = var.region
  pubsub_topic_id     = module.finops_alerts.pubsub_topic_id
  function_name       = "finops-budget-alert-processor"
  function_source_dir = "${path.module}/function-source"
  bucket_name         = var.function_bucket_name
  runtime             = var.function_runtime
  enable_function     = var.enable_alert_function

  service_account_email = "tf-executor@${var.project_id}.iam.gserviceaccount.com"

  environment_variables = {
    GMAIL_USER = var.gmail_user
  }

  secret_environment = {
    GMAIL_APP_PASSWORD = var.gmail_app_password
    TEAMS_WEBHOOK_URL  = var.teams_webhook_url
  }

  depends_on = [
    module.finops_foundation,
    module.finops_alerts,
    google_service_account_iam_member.compute_default_sa_act_as,
    google_service_account_iam_member.appspot_sa_act_as,
    google_service_account_iam_member.tf_sa_act_as,
  ]
}
