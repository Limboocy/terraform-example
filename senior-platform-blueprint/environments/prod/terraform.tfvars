# Non-secret environment inputs. Secrets (DD_API_KEY, ARM_* creds) come from the
# pipeline / env vars, never from this file.
project     = "aksplatform"
location    = "eastus"
cost_center = "CC-1001"
owner       = "platform-engineering"

# Placeholder Entra group object IDs — replace with real group GUIDs.
aks_admin_group_object_ids = [
  "00000000-0000-0000-0000-000000000000",
]

budget_start_date = "2026-01-01T00:00:00Z"
cost_alert_emails = ["platform-oncall@example.com"]
