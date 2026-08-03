# finops-budgets -- Billing Budgets + Reporting View

Creates GCP billing budgets with threshold-based Pub/Sub alerts, plus a
BigQuery view (finops_budgets) for dashboard KPI calculations.

## Usage

```hcl
module "finops_budgets" {
  source = "../modules/finops-budgets"
  billing_account          = "XXXXXX-XXXXXX-XXXXXX"
  project_id               = module.finops_dataset.project_id
  dataset_id               = module.finops_dataset.dataset_id
  pubsub_topic_id          = module.finops_alerts.pubsub_topic_id
  notification_channel_ids = values(module.finops_alerts.notification_channel_ids)
  budget_view_data = [
    { month = "2026-07", project_id = "my-project", currency = "USD", budget_amount = 5000 },
  ]
  budgets = {
    monthly_overall = {
      display_name  = "Monthly Overall"
      currency_code = "USD"
      units         = "5000"
      threshold_rules = [
        { threshold_percent = 0.5 },
        { threshold_percent = 1.0 },
      ]
    }
  }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| billing_account | string | required | Billing account ID |
| project_id | string | "" | Project for BigQuery view |
| dataset_id | string | "" | Dataset for BigQuery view |
| pubsub_topic_id | string | "" | Pub/Sub topic from Module 3 |
| notification_channel_ids | list(string) | [] | Notification channels from Module 3 |
| budget_view_data | list(object) | [] | Budget targets for BigQuery view |
| budgets | map(object) | {} | Budget definitions |

## Outputs

| Name | Description |
|---|---|
| budget_ids | Map of budget key to resource name |
| budget_names | Map of budget key to display name |
| finops_budgets_view_id | Fully qualified finops_budgets view ID |