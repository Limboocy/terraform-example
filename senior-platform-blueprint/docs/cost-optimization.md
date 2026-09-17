# Cost Optimization Playbook

Covers "monitor and optimize cloud costs while retaining performance and
reliability." Cost is treated as a first-class, measured constraint — not a
quarterly surprise.

## Guardrails already in code
- **Budgets** (`modules/cost-management`): per-env resource-group budget with a
  forecast alert at 80% and an actual alert at 100%, routed to the platform team.
- **infracost gate** (`.azuredevops/`): every PR shows the monthly cost delta of
  the change, so spend is reviewed alongside the diff.
- **Log ingestion caps** (`modules/log-analytics`): `daily_quota_gb` bounds Log
  Analytics spend in dev/staging (the usual runaway cost in AKS platforms).
- **Right-sized per env**: dev runs single-zone Free-tier smaller nodes; only
  prod pays for zone redundancy and the Standard SLA.

## Levers, ranked by typical savings

1. **Node autoscaling floors.** The largest recurring waste is idle nodes.
   `min_count` should be the smallest count that survives your failure model —
   in dev that's 1. Revisit floors quarterly against actual utilization.
2. **Spot node pool for interruptible workloads.** Add a spot user pool
   (`priority = "Spot"`, `eviction_policy = "Delete"`) for batch/CI/stateless
   workloads — 60-90% cheaper. Not in this blueprint by default; add per need.
3. **VM family fit.** D-series is a balanced default. CPU-bound → F-series;
   memory-bound → E-series. Wrong family = paying for unused dimension.
4. **Reserved Instances / Savings Plans** for the stable prod baseline (the
   `min_count` floor that never scales to zero). 1-year RI on the system pool
   baseline is low-risk. Purchased outside Terraform (billing scope).
5. **Log retention & quota.** 90-day prod retention is for compliance; dev/stg
   at 30 days. Sample or drop noisy container logs at the agent before ingest.
6. **Cluster stop in non-prod off-hours.** `az aks stop` dev/staging nights and
   weekends via a scheduled pipeline — pay only for storage while stopped.

## Monitoring
- Azure Cost Management → group by the `cost_center` and `environment` tags
  (enforced by `modules/governance`, which is *why* tag governance matters for
  cost, not just compliance).
- Datadog: correlate `kubernetes.cpu.usage` / node count against spend to catch
  over-provisioning that budgets alone won't show.

## Anti-patterns to avoid
- Cutting `min_count` below what survives a zone loss to save money — a prod
  outage costs more than the nodes.
- Disabling autoscaler max ceilings — you trade a cost cap for an availability
  cap under load. Alert on approaching max instead.
