# finops-budget-controls -- Scoped Budget Enforcement

Creates per-project or per-folder billing budgets with IAM controls. Each
scope gets its own budget with a project/folder filter. Also grants
roles/billing.viewer to specified members.

## Usage

```hcl
module "finops_budget_controls" {
  source = "../modules/finops-budget-controls"
  billing_account          = "XXXXXX-XXXXXX-XXXXXX"
  pubsub_topic_id          = module.finops_alerts.pubsub_topic_id
  notification_channel_ids = values(module.finops_alerts.notification_channel_ids)
  scopes = {
    dev_projects = {
      display_name    = "Dev Projects"
      currency_code   = "USD"
      units           = "2000"
      filter_projects = ["projects/my-dev-project"]
      threshold_rules = [
        { threshold_percent = 0.5 },
        { threshold_percent = 1.0 },
      ]
    }
  }
  iam_viewers = ["user:finops-team@example.com"]
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| billing_account | string | required | Billing account ID |
| pubsub_topic_id | string | "" | Pub/Sub topic from Module 3 |
| notification_channel_ids | list(string) | [] | Notification channels from Module 3 |
| scopes | map(object) | {} | Scoped budget definitions |
| iam_viewers | list(string) | [] | Members granted billing viewer |

## Outputs

| Name | Description |
|---|---|
| scoped_budget_ids | Map of scope key to budget resource name |