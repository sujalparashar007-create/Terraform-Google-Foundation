# ==============================================================================
# MODULE: finops-dataset — variables
# ==============================================================================

variable "project_id" {
  description = "GCP project ID where the BigQuery dataset will be created"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery dataset ID (must be unique within the project)"
  type        = string
  default     = "billing_export"
}

variable "location" {
  description = "BigQuery dataset location (regional or multi-regional)"
  type        = string
  default     = "EU"
}

variable "labels" {
  description = "Labels to apply to the BigQuery dataset"
  type        = map(string)
  default     = {}
}

variable "iam" {
  description = "Dataset-level IAM bindings. Key = IAM role, value = list of members"
  type        = map(list(string))
  default     = {}

  # Example:
  # {
  #   "roles/bigquery.dataViewer" = ["group:finops-team@example.com"]
  #   "roles/bigquery.dataEditor" = ["serviceAccount:etl-sa@..."]
  # }
}
