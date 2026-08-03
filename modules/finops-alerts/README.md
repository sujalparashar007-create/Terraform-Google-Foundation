# finops-alerts -- Spend Threshold Notifications

Creates a Pub/Sub topic and email notification channels for billing budget
alerts. Budgets in Module 2 and Module 4 wire into this Pub/Sub topic.

## Usage

```hcl
module "finops_alerts" {
  source = "../modules/finops-alerts"
  project_id   = "myco-finops-abc123"
  topic_name   = "finops-budget-alerts"
  alert_emails = ["finops-team@example.com"]
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| project_id | string | required | GCP project ID |
| topic_name | string | finops-budget-alerts | Pub/Sub topic name |
| alert_emails | list(string) | [] | Email recipients for notifications |

## Outputs

| Name | Description |
|---|---|
| pubsub_topic_id | Full Pub/Sub topic ID |
| pubsub_topic_name | Short Pub/Sub topic name |
| notification_channel_ids | Map of email to notification channel ID |