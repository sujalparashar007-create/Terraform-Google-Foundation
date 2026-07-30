# ==============================================================================
# MODULE: finops-budget-controls — Scoped Budget Enforcement (Module 4)
# ==============================================================================
# Creates per-project or per-folder billing budgets with IAM controls.
# Each scope gets its own google_billing_budget with budget_filter.
# ==============================================================================

resource "google_billing_budget" "scoped" {
  for_each = var.scopes

  billing_account = var.billing_account
  display_name    = each.value.display_name

  amount {
    specified_amount {
      currency_code = each.value.currency_code
      units         = each.value.units
    }
  }

  dynamic "threshold_rules" {
    for_each = each.value.threshold_rules
    content {
      threshold_percent = threshold_rules.value.threshold_percent
      spend_basis       = try(threshold_rules.value.spend_basis, "CURRENT_SPEND")
    }
  }

  all_updates_rule {
    pubsub_topic                     = var.pubsub_topic_id != "" ? var.pubsub_topic_id : null
    monitoring_notification_channels = coalescelist(each.value.monitoring_notification_channels, var.notification_channel_ids)
    disable_default_iam_recipients   = try(each.value.disable_default_iam_recipients, false)
    enable_project_level_recipients  = try(each.value.enable_project_level_recipients, true)
  }

  budget_filter {
    projects               = try(each.value.filter_projects, null)
    credit_types_treatment = try(each.value.credit_types_treatment, "INCLUDE_ALL_CREDITS")
    labels                 = try(each.value.filter_labels, null)
    calendar_period        = try(each.value.calendar_period, "MONTH")
  }
}

# IAM — billing budgets viewer for all, admin for FinOps team
resource "google_billing_account_iam_member" "viewer" {
  for_each = toset(var.iam_viewers)

  billing_account_id = var.billing_account
  role               = "roles/billing.viewer"
  member             = each.key
}
