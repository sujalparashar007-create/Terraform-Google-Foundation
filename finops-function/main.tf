# ==============================================================================
# MODULE: finops-function > Budget Alert Cloud Function (2nd gen)
# ==============================================================================

# GCS bucket to store the Cloud Function source code
resource "google_storage_bucket" "function_source" {
  name     = var.bucket_name
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
  force_destroy               = true
}

# Zip the function source code
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = var.function_source_dir
  output_path = "${path.module}/function-source.zip"
}

# Upload the zip to GCS
resource "google_storage_bucket_object" "function_zip" {
  name   = "function-${data.archive_file.function_zip.output_sha256}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_zip.output_path
}

# ------------------------------------------------------------------------------
# SECRET MANAGER > store sensitive credentials instead of plaintext env vars
# ------------------------------------------------------------------------------

resource "google_secret_manager_secret" "secrets" {
  for_each = var.secret_environment

  secret_id = "${var.function_name}-${each.key}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    managed_by = "terraform"
  }
}

resource "google_secret_manager_secret_version" "versions" {
  for_each = var.secret_environment

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value

  depends_on = [google_secret_manager_secret.secrets]
}

# Grant the Cloud Function SA access to read the secrets
resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = var.secret_environment

  secret_id = google_secret_manager_secret.secrets[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.service_account_email}"
}

# Grant Pub/Sub (via Eventarc) permission to invoke the Cloud Run service
resource "google_cloud_run_service_iam_member" "pubsub_invoker" {
  project  = var.project_id
  location = var.region
  service  = var.function_name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ------------------------------------------------------------------------------
# CLOUD FUNCTION
# ------------------------------------------------------------------------------

locals {
  service_account_email = var.service_account_email != "" ? var.service_account_email : "tf-executor@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_cloudfunctions2_function" "alert_processor" {
  count       = var.enable_function ? 1 : 0
  name        = var.function_name
  location    = var.region
  project     = var.project_id
  description = "Processes budget alert messages from Pub/Sub and logs them to Cloud Logging"

  build_config {
    runtime     = var.runtime
    entry_point = "process_budget_alert"

    source {
      storage_source {
        bucket = google_storage_bucket_object.function_zip.bucket
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    max_instance_count    = var.max_instance_count
    available_memory      = var.available_memory
    timeout_seconds       = var.timeout_seconds
    service_account_email = local.service_account_email

    environment_variables = var.environment_variables

    dynamic "secret_environment_variables" {
      for_each = var.secret_environment
      content {
        key        = secret_environment_variables.key
        project_id = var.project_id
        secret     = google_secret_manager_secret.secrets[secret_environment_variables.key].secret_id
        version    = "latest"
      }
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = var.pubsub_topic_id
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_secret_manager_secret_version.versions
  ]
}



