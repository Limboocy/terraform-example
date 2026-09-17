# Cost guardrails for an environment: a resource-group budget with staged
# alerts (forecast + actual) that notify the platform team before spend runs
# away. This is the "monitor and optimize cloud costs" responsibility as code.

resource "azurerm_monitor_action_group" "cost" {
  name                = "${var.project}-${var.environment}-cost-ag"
  resource_group_name = var.resource_group_name
  short_name          = substr("${var.environment}cost", 0, 12)

  dynamic "email_receiver" {
    for_each = var.alert_emails
    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }

  tags = var.tags
}

resource "azurerm_consumption_budget_resource_group" "this" {
  name              = "${var.project}-${var.environment}-budget"
  resource_group_id = var.resource_group_id

  amount     = var.monthly_budget
  time_grain = "Monthly"

  time_period {
    # Budgets need a start date on the first of a month.
    start_date = var.budget_start_date
  }

  # Warn on forecast (early signal) and on actual (hard signal).
  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_groups = [azurerm_monitor_action_group.cost.id]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_groups = [azurerm_monitor_action_group.cost.id]
  }
}
