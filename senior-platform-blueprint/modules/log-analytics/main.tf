# Central Log Analytics workspace for an environment. Consumed by AKS (oms
# agent), Microsoft Defender, NSG flow logs, and diagnostic settings.

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.project}-${var.environment}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days

  # Cost guardrail: cap ingestion so a runaway log source can't blow the bill.
  # -1 means unlimited; environments set a real cap.
  daily_quota_gb = var.daily_quota_gb

  tags = var.tags
}
