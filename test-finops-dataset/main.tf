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
# LOCALS: load budget configuration from YAML
# ------------------------------------------------------------------------------
locals {
  budget_config = yamldecode(file(var.budgets_yaml_path))
}

# ==============================================================================
# STEP 1: Permissions for Terraform Service Account
# Applied FIRST so downstream modules have the roles they need.
# ==============================================================================

resource "google_project_iam_member" "tf_sa_bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "tf_sa_pubsub_admin" {
  project = var.project_id
  role    = "roles/pubsub.admin"
  member  = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "tf_sa_monitoring_editor" {
  project = var.project_id
  role    = "roles/monitoring.editor"
  member  = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "tf_sa_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "tf_sa_cloudfunctions_admin" {
  project = var.project_id
  role    = "roles/cloudfunctions.admin"
  member  = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}
resource "google_service_account_iam_member" "tf_sa_act_as" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/tf-executor@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "compute_sa_act_as" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.project_id}@appspot.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

# NOTE: This requires the TF SA to already have billing.admin (manual bootstrapping).
# Once granted manually, Terraform can manage it going forward.
resource "google_billing_account_iam_member" "tf_sa_billing_admin" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.admin"
  member             = "serviceAccount:tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

# ==============================================================================
# STEP 2: Enable Required APIs
# ==============================================================================

resource "google_project_service" "billingbudgets" {
  project = var.project_id
  service = "billingbudgets.googleapis.com"
}

resource "google_project_service" "pubsub" {
  project = var.project_id
  service = "pubsub.googleapis.com"
}

resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"
}

# ==============================================================================
# STEP 3: Module 0 - BigQuery Dataset (depends on BigQuery IAM)
# ==============================================================================

module "finops_dataset" {
  source = "../modules/finops-dataset"

  project_id = var.project_id
  dataset_id = var.dataset_id
  location   = var.dataset_location

  labels = var.labels

  iam = var.dataset_iam

  depends_on = [
    google_project_iam_member.tf_sa_bigquery_admin
  ]
}

# ==============================================================================
# STEP 4: Module 1 - 6 SQL Reporting Views (depends on dataset)
# ==============================================================================

module "finops_views" {
  source = "../modules/finops-views"

  project_id = module.finops_dataset.project_id
  dataset_id = module.finops_dataset.dataset_id

  billing_export_table_id = var.billing_export_table_id

  depends_on = [
    module.finops_dataset
  ]
}

# ==============================================================================
# STEP 5: Module 3 - Pub/Sub + Email Alert Channels (depends on APIs + IAM)
# ==============================================================================

module "finops_alerts" {
  source = "../modules/finops-alerts"

  project_id   = module.finops_dataset.project_id
  topic_name   = var.topic_name
  alert_emails = var.alert_emails

  depends_on = [
    google_project_service.pubsub,
    google_project_service.monitoring,
    google_project_iam_member.tf_sa_pubsub_admin,
    google_project_iam_member.tf_sa_monitoring_editor
  ]
}

# ==============================================================================
# STEP 6: Module 2 - Billing Budgets (depends on alerts + billingbudgets API)
# ==============================================================================

module "finops_budgets" {
  source = "../modules/finops-budgets"

  billing_account          = var.billing_account_id
  project_id               = module.finops_dataset.project_id
  dataset_id               = module.finops_dataset.dataset_id
  pubsub_topic_id          = module.finops_alerts.pubsub_topic_id
  notification_channel_ids = values(module.finops_alerts.notification_channel_ids)

  budget_view_data = local.budget_config.budget_view_data

  budgets = local.budget_config.budgets

  depends_on = [
    google_project_service.billingbudgets,
    google_billing_account_iam_member.tf_sa_billing_admin,
    module.finops_alerts
  ]
}

# ==============================================================================
# STEP 7: Module 4 - Scoped Budget Controls (depends on alerts)
# ==============================================================================

module "finops_budget_controls" {
  source = "../modules/finops-budget-controls"

  billing_account          = var.billing_account_id
  pubsub_topic_id          = module.finops_alerts.pubsub_topic_id
  notification_channel_ids = values(module.finops_alerts.notification_channel_ids)

  scopes = local.budget_config.budget_control_scopes

  iam_viewers = var.iam_viewers

  depends_on = [
    google_billing_account_iam_member.tf_sa_billing_admin,
    module.finops_alerts
  ]
}

# ==============================================================================
# STEP 8: Module 5 - monthly_kpi_summary (joins daily_cost + finops_budgets)
# ==============================================================================

resource "google_bigquery_table" "monthly_kpi_summary" {
  project       = module.finops_dataset.project_id
  dataset_id    = module.finops_dataset.dataset_id
  table_id      = "monthly_kpi_summary"
  friendly_name = "Monthly KPI Summary"

  view {
    query          = <<-EOT
      WITH monthly_actuals AS (
        SELECT
          FORMAT_TIMESTAMP('%Y-%m', usage_date) AS month,
          project_id,
          project_name,
          SUM(net_cost)    AS net_spend,
          SUM(gross_cost)  AS gross_spend,
          SUM(total_credits) AS credits_applied
        FROM `${module.finops_dataset.project_id}.${module.finops_dataset.dataset_id}.daily_cost`
        GROUP BY 1, 2, 3
      ),
      budget_targets AS (
        SELECT month, project_id, currency, budget_amount
        FROM `${module.finops_dataset.project_id}.${module.finops_dataset.dataset_id}.finops_budgets`
      ),
      kpi AS (
        SELECT
          a.month,
          a.project_id,
          a.project_name,
          a.gross_spend,
          a.credits_applied,
          a.net_spend,
          b.currency,
          b.budget_amount,
          (a.net_spend - b.budget_amount) AS budget_variance,
          SAFE_DIVIDE(a.net_spend, b.budget_amount) * 100 AS budget_utilization_pct,
          LAG(a.net_spend) OVER (PARTITION BY a.project_id ORDER BY a.month) AS prev_month_spend,
          SAFE_DIVIDE(
            a.net_spend - LAG(a.net_spend) OVER (PARTITION BY a.project_id ORDER BY a.month),
            LAG(a.net_spend) OVER (PARTITION BY a.project_id ORDER BY a.month)
          ) * 100 AS mom_pct
        FROM monthly_actuals a
        LEFT JOIN budget_targets b
          ON a.project_id = b.project_id AND a.month = b.month
      )
      SELECT * FROM kpi
      ORDER BY month DESC, project_id
    EOT
    use_legacy_sql = false
  }

  deletion_protection = false

  depends_on = [
    module.finops_views,
    module.finops_budgets
  ]
}

# ==============================================================================
# STEP 9: Cloud Function - Budget Alert Processor
# ==============================================================================
# Triggered by Pub/Sub finops-budget-alerts topic. Logs budget alert messages.
# ==============================================================================

# Additional APIs needed for Cloud Functions 2nd gen
resource "google_project_service" "cloudbuild" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "cloudfunctions" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "cloudrun" {
  project = var.project_id
  service = "run.googleapis.com"
}

resource "google_project_service" "eventarc" {
  project = var.project_id
  service = "eventarc.googleapis.com"
}

resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
}

# GCS bucket to store the Cloud Function source code
resource "google_storage_bucket" "function_source_bucket" {
  depends_on = [google_project_iam_member.tf_sa_storage_admin]
  name       = var.function_bucket_name
  location   = var.region
  project    = var.project_id

  uniform_bucket_level_access = true
  force_destroy               = true
}

# Zip the function source code
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function-source"
  output_path = "${path.module}/function-source.zip"
}

# Upload the zip to GCS
resource "google_storage_bucket_object" "function_zip" {
  name   = "function-${data.archive_file.function_zip.output_sha256}.zip"
  bucket = google_storage_bucket.function_source_bucket.name
  source = data.archive_file.function_zip.output_path
}

# Cloud Function 2nd gen - triggered by Pub/Sub budget alerts
# Set enable_alert_function = false to stop emails & Teams messages
resource "google_cloudfunctions2_function" "budget_alert_processor" {
  count       = var.enable_alert_function ? 1 : 0
  name        = "finops-budget-alert-processor"
  location    = var.region
  project     = var.project_id
  description = "Processes budget alert messages from Pub/Sub and logs them to Cloud Logging"

  build_config {
    runtime     = var.function_runtime
    entry_point = "process_budget_alert"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source_bucket.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = "tf-executor@${var.project_id}.iam.gserviceaccount.com"

    environment_variables = {
      GMAIL_USER         = var.gmail_user
      GMAIL_APP_PASSWORD = var.gmail_app_password
      TEAMS_WEBHOOK_URL  = var.teams_webhook_url
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = module.finops_alerts.pubsub_topic_id
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.cloudrun,
    google_project_service.eventarc,
    google_project_service.artifactregistry,
    google_storage_bucket_object.function_zip,
    module.finops_alerts
  ]
}
