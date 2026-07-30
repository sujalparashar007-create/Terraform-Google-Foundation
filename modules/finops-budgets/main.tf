# ==============================================================================
# MODULE: finops-budgets — Billing Budgets + Reporting View (Module 2)
# ==============================================================================

# Enforcement: real GCP billing budgets
resource "google_billing_budget" "budget" {
  for_each = var.budgets

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
    disable_default_iam_recipients   = each.value.disable_default_iam_recipients
    enable_project_level_recipients  = each.value.enable_project_level_recipients
  }

  budget_filter {
    credit_types_treatment = try(each.value.credit_types_treatment, "INCLUDE_ALL_CREDITS")
  }
}

# Reporting: BigQuery view for dashboard joins
resource "google_bigquery_table" "finops_budgets_view" {
  count = var.project_id != "" && length(var.budget_view_data) > 0 ? 1 : 0

  project       = var.project_id
  dataset_id    = var.dataset_id
  table_id      = "finops_budgets"
  friendly_name = "FinOps Budgets"

  view {
    query          = <<-EOT
      SELECT month, project_id, currency, budget_amount
      FROM UNNEST([
        %{for i, row in var.budget_view_data}
        STRUCT("${row.month}" AS month, "${row.project_id}" AS project_id, "${row.currency}" AS currency, ${row.budget_amount} AS budget_amount)%{if i < length(var.budget_view_data) - 1},%{endif}
        %{endfor}
      ])
    EOT
    use_legacy_sql = false
  }

  deletion_protection = false
}
