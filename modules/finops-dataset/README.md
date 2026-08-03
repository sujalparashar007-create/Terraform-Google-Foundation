# finops-dataset -- BigQuery Dataset for FinOps Reporting

Creates a BigQuery dataset to host all FinOps reporting views, plus
dataset-level IAM bindings for consumers.

## Usage

```hcl
module "finops_dataset" {
  source = "../modules/finops-dataset"
  project_id = "myco-finops-abc123"
  dataset_id = "billing_export"
  location   = "EU"
  iam = {
    "roles/bigquery.dataViewer" = ["group:finops-team@example.com"]
  }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| project_id | string | required | GCP project ID |
| dataset_id | string | billing_export | BigQuery dataset ID |
| location | string | EU | Dataset location (regional or multi-regional) |
| labels | map(string) | {} | Labels for the dataset |
| iam | map(list(string)) | {} | Dataset-level IAM bindings |

## Outputs

| Name | Description |
|---|---|
| dataset_id | BigQuery dataset ID |
| project_id | GCP project ID (passthrough) |
| dataset_full_id | Fully qualified reference (project.dataset) |