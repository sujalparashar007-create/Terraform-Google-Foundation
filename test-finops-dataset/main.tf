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
#   Billing -> Account Management -> 01A325-032DBC-FAB4E4 -> Permissions
#   Add: tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com
#   Role: Billing Account Administrator
# ==============================================================================

# ==============================================================================
# STEP 1: Permissions for Terraform Service Account
# Applied FIRST so downstream modules have the roles they need.
# ==============================================================================

resource "google_project_iam_member" "tf_sa_bigquery_admin" {
  project = "foundation-bootstrap-seed"
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "tf_sa_pubsub_admin" {
  project = "foundation-bootstrap-seed"
  role    = "roles/pubsub.admin"
  member  = "serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "tf_sa_monitoring_editor" {
  project = "foundation-bootstrap-seed"
  role    = "roles/monitoring.editor"
  member  = "serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "tf_sa_storage_admin" {
  project = "foundation-bootstrap-seed"
  role    = "roles/storage.admin"
  member  = "serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "tf_sa_cloudfunctions_admin" {
  project = "foundation-bootstrap-seed"
  role    = "roles/cloudfunctions.admin"
  member  = "serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"
}
resource "google_service_account_iam_member" "tf_sa_act_as" {
  service_account_id = "projects/foundation-bootstrap-seed/serviceAccounts/tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "compute_sa_act_as" {
  service_account_id = "projects/foundation-bootstrap-seed/serviceAccounts/128258208668-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"
}

# NOTE: This requires the TF SA to already have billing.admin (manual bootstrapping).
# Once granted manually, Terraform can manage it going forward.
resource "google_billing_account_iam_member" "tf_sa_billing_admin" {
  billing_account_id = "01A325-032DBC-FAB4E4"
  role               = "roles/billing.admin"
  member             = "serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"
}

# ==============================================================================
# STEP 2: Enable Required APIs
# ==============================================================================

resource "google_project_service" "billingbudgets" {
  project = "foundation-bootstrap-seed"
  service = "billingbudgets.googleapis.com"
}

resource "google_project_service" "pubsub" {
  project = "foundation-bootstrap-seed"
  service = "pubsub.googleapis.com"
}

resource "google_project_service" "monitoring" {
  project = "foundation-bootstrap-seed"
  service = "monitoring.googleapis.com"
}

# ==============================================================================
# STEP 3: Module 0 - BigQuery Dataset (depends on BigQuery IAM)
# ==============================================================================

module "finops_dataset" {
  source = "../modules/finops-dataset"

  project_id = "foundation-bootstrap-seed"
  dataset_id = "billing_export"
  location   = "EU"

  labels = {
    environment = "demo"
    managed_by  = "terraform"
  }

  iam = {
    "roles/bigquery.dataViewer" = [
      "user:sujalparashar007@gmail.com"
    ]
  }

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

  billing_export_table_id = "project-6f3b3c54-b345-4d07-be1.billing_export.gcp_billing_export_resource_v1_01A325_032DBC_FAB4E4"

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
  topic_name   = "finops-budget-alerts"
  alert_emails = ["sujalparashar007@gmail.com"]

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

  billing_account          = "01A325-032DBC-FAB4E4"
  project_id               = module.finops_dataset.project_id
  dataset_id               = module.finops_dataset.dataset_id
  pubsub_topic_id          = module.finops_alerts.pubsub_topic_id
  notification_channel_ids = values(module.finops_alerts.notification_channel_ids)

  budget_view_data = [
    { month = "2026-07", project_id = "foundation-bootstrap-seed", currency = "INR", budget_amount = 50000 },
    { month = "2026-08", project_id = "foundation-bootstrap-seed", currency = "INR", budget_amount = 50000 },
  ]

  budgets = {
    monthly_overall = {
      display_name  = "Monthly Overall Budget"
      currency_code = "INR"
      units         = "50000"

      threshold_rules = [
        { threshold_percent = 0.5 },
        { threshold_percent = 0.8 },
        { threshold_percent = 1.0 },
      ]

      credit_types_treatment          = "EXCLUDE_ALL_CREDITS"
      enable_project_level_recipients = true
    }
  }

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

  billing_account          = "01A325-032DBC-FAB4E4"
  pubsub_topic_id          = module.finops_alerts.pubsub_topic_id
  notification_channel_ids = values(module.finops_alerts.notification_channel_ids)

  scopes = {
    dev_projects = {
      display_name    = "Dev Projects Budget"
      currency_code   = "INR"
      units           = "20000"
      filter_projects = ["projects/foundation-bootstrap-seed"]
      threshold_rules = [
        { threshold_percent = 0.5 },
        { threshold_percent = 1.0 },
      ]
    }
  }

  iam_viewers = [
    "user:sujalparashar007@gmail.com",
  ]

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
  project = "foundation-bootstrap-seed"
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "cloudfunctions" {
  project = "foundation-bootstrap-seed"
  service = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "cloudrun" {
  project = "foundation-bootstrap-seed"
  service = "run.googleapis.com"
}

resource "google_project_service" "eventarc" {
  project = "foundation-bootstrap-seed"
  service = "eventarc.googleapis.com"
}

resource "google_project_service" "artifactregistry" {
  project = "foundation-bootstrap-seed"
  service = "artifactregistry.googleapis.com"
}

# GCS bucket to store the Cloud Function source code
resource "google_storage_bucket" "function_source_bucket" {
  depends_on = [google_project_iam_member.tf_sa_storage_admin]
  name       = "foundation-finops-function-source"
  location   = "us-east1"
  project    = "foundation-bootstrap-seed"

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
resource "google_cloudfunctions2_function" "budget_alert_processor" {
  name        = "finops-budget-alert-processor"
  location    = "us-east1"
  project     = "foundation-bootstrap-seed"
  description = "Processes budget alert messages from Pub/Sub and logs them to Cloud Logging"

  build_config {
    runtime     = "python311"
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
    service_account_email = "tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"

    environment_variables = {
      GMAIL_USER         = "sujalparashar007@gmail.com"
      GMAIL_APP_PASSWORD = "mpdh pdnt ickl ygll"
      TEAMS_WEBHOOK_URL  = "https://default9274ee3f94254109a27f9fb15c1067.5d.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/f65710364b934191846154e8e6917df8/triggers/manual/paths/invoke?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=ogSLKC28GyxDPcRGhXM77bd9jbtffvcIE0Op5Wd28zQ"
    }
  }

  event_trigger {
    trigger_region = "us-east1"
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
