# ==============================================================================
# MODULE: finops-budget-controls — variables
# ==============================================================================

variable "billing_account" {
  description = "GCP billing account ID"
  type        = string
}

variable "pubsub_topic_id" {
  description = "Full Pub/Sub topic ID from Module 3 for alerts"
  type        = string
  default     = ""
}

variable "notification_channel_ids" {
  description = "List of notification channel IDs from Module 3"
  type        = list(string)
  default     = []
}

variable "scopes" {
  description = "Map of scoped budget definitions (per project/folder)"
  type = map(object({
    display_name  = string
    currency_code = optional(string, "USD")
    units         = string
    threshold_rules = list(object({
      threshold_percent = number
      spend_basis       = optional(string, "CURRENT_SPEND")
    }))
    filter_projects                  = optional(list(string))
    filter_labels                    = optional(map(string))
    credit_types_treatment           = optional(string, "INCLUDE_ALL_CREDITS")
    calendar_period                  = optional(string, "MONTH")
    monitoring_notification_channels = optional(list(string), [])
    disable_default_iam_recipients   = optional(bool, false)
    enable_project_level_recipients  = optional(bool, true)
  }))
  default = {}
}

variable "iam_viewers" {
  description = "List of members to grant billing viewer (can see budgets)"
  type        = list(string)
  default     = []
}
