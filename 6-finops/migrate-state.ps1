# State migration script for 6-finops refactoring
# Run from 6-finops directory: .\migrate-state.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "=== F7: IAM members -> finops-foundation ===" -ForegroundColor Cyan
terraform state mv -lock=false `
  'google_project_iam_member.tf_sa_bigquery_admin' `
  'module.finops_foundation.google_project_iam_member.members["roles/bigquery.admin/serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"]'
terraform state mv -lock=false `
  'google_project_iam_member.tf_sa_pubsub_admin' `
  'module.finops_foundation.google_project_iam_member.members["roles/pubsub.admin/serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"]'
terraform state mv -lock=false `
  'google_project_iam_member.tf_sa_monitoring_editor' `
  'module.finops_foundation.google_project_iam_member.members["roles/monitoring.editor/serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"]'
terraform state mv -lock=false `
  'google_project_iam_member.tf_sa_storage_admin' `
  'module.finops_foundation.google_project_iam_member.members["roles/storage.admin/serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"]'
terraform state mv -lock=false `
  'google_project_iam_member.tf_sa_cloudfunctions_admin' `
  'module.finops_foundation.google_project_iam_member.members["roles/cloudfunctions.admin/serviceAccount:tf-executor@foundation-bootstrap-seed.iam.gserviceaccount.com"]'

Write-Host "=== F13: APIs -> state rm (will be recreated harmlessly) ===" -ForegroundColor Cyan
terraform state rm -lock=false google_project_service.artifactregistry
terraform state rm -lock=false google_project_service.billingbudgets
terraform state rm -lock=false google_project_service.cloudbuild
terraform state rm -lock=false google_project_service.cloudfunctions
terraform state rm -lock=false google_project_service.cloudrun
terraform state rm -lock=false google_project_service.eventarc
terraform state rm -lock=false google_project_service.monitoring
terraform state rm -lock=false google_project_service.pubsub

Write-Host "=== F8: Cloud Function resources -> finops-function ===" -ForegroundColor Cyan
terraform state mv -lock=false `
  'google_cloudfunctions2_function.budget_alert_processor[0]' `
  'module.finops_function.google_cloudfunctions2_function.alert_processor[0]'
terraform state mv -lock=false `
  'google_storage_bucket.function_source_bucket' `
  'module.finops_function.google_storage_bucket.function_source'
terraform state mv -lock=false `
  'google_storage_bucket_object.function_zip' `
  'module.finops_function.google_storage_bucket_object.function_zip'
terraform state rm -lock=false data.archive_file.function_zip

Write-Host "=== F2: budget_controls -> finops_budgets ===" -ForegroundColor Cyan
terraform state mv -lock=false `
  'module.finops_budget_controls.google_billing_budget.scoped["dev_projects"]' `
  'module.finops_budgets.google_billing_budget.budget["dev_projects"]'
terraform state mv -lock=false `
  'module.finops_budget_controls.google_billing_account_iam_member.viewer["user:sujalparashar007@gmail.com"]' `
  'module.finops_budgets.google_billing_account_iam_member.viewer["user:sujalparashar007@gmail.com"]'

Write-Host "=== F3: Views -> finops_views ===" -ForegroundColor Cyan
terraform state mv -lock=false `
  'google_bigquery_table.monthly_kpi_summary' `
  'module.finops_views.google_bigquery_table.views["monthly_kpi_summary"]'
terraform state mv -lock=false `
  'module.finops_budgets.google_bigquery_table.finops_budgets_view[0]' `
  'module.finops_views.google_bigquery_table.views["finops_budgets"]'

Write-Host "=== Migration complete ===" -ForegroundColor Green
terraform state list
