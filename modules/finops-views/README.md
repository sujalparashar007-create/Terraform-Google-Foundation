# finops-views -- FinOps Reporting SQL Views Factory

Creates 6 BigQuery views from raw GCP billing export data:
1. daily_cost -- Day-grain net cost per project/service
2. monthly_cost_trend -- Monthly rollup by project/service
3. cost_by_project -- Monthly net cost + percent of total per project
4. top_skus -- Monthly cost ranked by service/SKU
5. discounts_and_commitments -- Credits by type
6. cost_anomalies -- Daily z-score spike detection

## Usage

```hcl
module "finops_views" {
  source = "../modules/finops-views"
  project_id              = module.finops_dataset.project_id
  dataset_id              = module.finops_dataset.dataset_id
  billing_export_table_id = "myco.billing_export.gcp_billing_export_resource_v1_XXXXXX"
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| project_id | string | required | GCP project ID |
| dataset_id | string | required | BigQuery dataset ID |
| billing_export_table_id | string | "" | Billing export table; empty = no views created |

## Outputs

| Name | Description |
|---|---|
| view_ids | Map of view name to fully qualified table ID |
| project_id | GCP project ID (passthrough) |
| dataset_id | BigQuery dataset ID (passthrough) |