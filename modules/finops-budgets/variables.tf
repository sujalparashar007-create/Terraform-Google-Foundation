# ==============================================================================
# MODULE: finops-budgets - variables
# ==============================================================================

variable "billing_account" {
  description = "GCP billing account ID"
  type        = string

  validation {
    condition     = can(regex("^[A-F0-9]{6}-[A-F0-9]{6}-[A-F0-9]{6}$", var.billing_account))
    error_message = "billing_account must match pattern XXXXXX-XXXXXX-XXXXXX."
  }
}

variable "project_id" {
  description = "Project for the finops_budgets BigQuery view"
  type        = string
  default     = ""
}

variable "dataset_id" {
  description = "Dataset for the finops_budgets BigQuery view"
  type        = string
  default     = ""
}

variable "pubsub_topic_id" {
  description = "Full Pub/Sub topic ID from Module 3"
  type        = string
  default     = ""
}

variable "notification_channel_ids" {
  description = "List of notification channel IDs from Module 3"
  type        = list(string)
  default     = []
}

variable "budget_view_data" {
  description = "Budget data for the finops_budgets BigQuery view"
  type = list(object({
    month         = string
    project_id    = string
    currency      = string
    budget_amount = number
  }))
  default = []
}

variable "budgets" {
  description = "Map of budget definitions"
  type = map(object({
    display_name  = string
    currency_code = optional(string, "USD")
    units         = string
    threshold_rules = list(object({
      threshold_percent = number
      spend_basis       = optional(string, "CURRENT_SPEND")
    }))
    monitoring_notification_channels = optional(list(string), [])
    disable_default_iam_recipients   = optional(bool, false)
    enable_project_level_recipients  = optional(bool, true)
    credit_types_treatment           = optional(string, "INCLUDE_ALL_CREDITS")
  }))
  default = {}
}
