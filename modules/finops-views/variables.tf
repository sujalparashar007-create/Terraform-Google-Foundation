# ==============================================================================
# MODULE: finops-views — variables
# ==============================================================================

variable "project_id" {
  description = "GCP project ID where the BigQuery views will be created"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery dataset ID (from Module 0 output)"
  type        = string
}

variable "billing_export_table_id" {
  description = "Fully qualified billing export table ID (project.dataset.gcp_billing_export_resource_v1_XXXXXX). Leave empty if billing export is not yet configured — no views will be created."
  type        = string
  default     = ""
}
