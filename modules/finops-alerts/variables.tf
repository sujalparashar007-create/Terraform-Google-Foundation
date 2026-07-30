# ==============================================================================
# MODULE: finops-alerts — variables
# ==============================================================================

variable "project_id" {
  description = "GCP project ID where Pub/Sub topic and notification channels are created"
  type        = string
}

variable "topic_name" {
  description = "Pub/Sub topic name for budget alert events"
  type        = string
  default     = "finops-budget-alerts"
}

variable "alert_emails" {
  description = "List of email addresses to notify on budget threshold breaches"
  type        = list(string)
  default     = []
}
