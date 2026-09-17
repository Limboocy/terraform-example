# AKS Platform — Terraform Blueprint

A production-shaped Infrastructure-as-Code platform for running applications on
Azure Kubernetes Service (AKS), with observability, cost, and governance managed
as code. This is a **learning blueprint**: it is structured and hardened the way
a real senior platform-engineering repo is, so you can study the practices and
adapt them.

> Mock notice: identifiers like subscription/tenant IDs, Entra group object IDs,
> storage account names, and Slack/PagerDuty handles are placeholders. Nothing
> here provisions real infrastructure until you supply real values and
> credentials. See [Getting started](#getting-started).

---

## Architecture at a glance

```
                         ┌────────────────────────────────────────────┐
                         │  Azure DevOps pipeline                      │
                         │  validate → scan → plan(artifact) → approve │
                         │  → apply(same artifact)                     │
                         └───────────────┬────────────────────────────┘
                                         │ OIDC (no stored secrets)
        ┌────────────────────────────────┼────────────────────────────────┐
        ▼                                 ▼                                 ▼
   environments/dev              environments/staging             environments/prod
        │                                 │                                 │
        └──────── each composes the same modules with env-specific inputs ──┘
                                          │
   ┌──────────────┬──────────────┬────────┴───────┬───────────────┬───────────────┐
   ▼              ▼              ▼                ▼               ▼               ▼
 networking   log-analytics   aks-cluster   observability-   cost-management  governance
 (vnet/nsg/   (workspace,     (private,     datadog          (budget +        (Azure Policy
  flowlogs)    quota)          zonal, AAD,  (monitors,SLO,   action group)    tag enforce)
                               auto-upgrade) dashboard)
```

State lives in an Azure Storage backend (created once by `bootstrap/`), one
state file per environment, with native blob-lease locking.

---

## Repository layout

| Path | Purpose |
|---|---|
| `bootstrap/` | One-time: creates the remote-state storage account (GRS, versioned, key-auth disabled). |
| `modules/networking/` | RG, VNet, AKS + private-endpoint subnets, deny-default NSG, optional flow logs. |
| `modules/log-analytics/` | Per-env workspace with retention + ingestion quota. |
| `modules/aks-cluster/` | Hardened AKS: zonal, paid SLA tier, private API, Entra RBAC, auto-upgrade window, workload identity, Defender, policy add-on. |
| `modules/observability-datadog/` | Parameterized monitors, an SLO, and a dashboard — all as code. |
| `modules/cost-management/` | Resource-group budget with forecast + actual alerts. |
| `modules/governance/` | Azure Policy assignments enforcing required tags. |
| `environments/{dev,staging,prod}/` | Composition roots — wire modules with env-specific inputs and isolated state. |
| `.azuredevops/` | Delivery pipeline + reusable step templates. |
| `policy/opa/` | Conftest/OPA rules run against the plan JSON in CI. |
| `Makefile` | Local equivalents of the CI gates. |
| `docs/` | Architecture, upgrade runbook, cost playbook. |

---

## Environment differences (why they differ)

| Setting | dev | staging | prod |
|---|---|---|---|
| Control-plane SKU | Free (no SLA) | Standard | Standard |
| API server | Public + IP allowlist | Private | Private |
| Availability zones | 1 | 3 | 3 |
| App pool max nodes | 3 | 6 | 20 |
| Log retention | 30d (5GB cap) | 30d (10GB cap) | 90d (no cap) |
| Alerts route to | Slack (P4) | Slack (P3) | Slack + PagerDuty (P1) |
| Monthly budget | 800 | 3000 | 8000 |

The differences are deliberate cost/risk tradeoffs, not accidents — dev
optimizes for cost, prod for availability and auditability.

---

## Getting started

Prerequisites: Terraform >= 1.7, Azure CLI, an Azure subscription, a Datadog
account (API + APP keys), and Entra ID admin group object IDs.

```bash
# 0. Authenticate
az login
export DD_API_KEY=... DD_APP_KEY=...

# 1. Bootstrap remote state (once per org)
cd bootstrap
terraform init && terraform apply
#    -> copy the backend_config output into each environments/*/terraform.tf

# 2. Fill in real values
#    - environments/<env>/terraform.tfvars: cost_center, admin group IDs, IP ranges
#    - each terraform.tf backend block: storage_account_name from step 1

# 3. Plan an environment
cd ../environments/dev
terraform init
terraform plan

# Or use the Makefile from the repo root:
make check ENV=dev      # fmt + validate + lint + security scan
make plan  ENV=dev
```

Secrets are never committed: Datadog keys come from `DD_API_KEY`/`DD_APP_KEY`,
Azure auth from your CLI session (local) or workload-identity federation (CI).

---

## How this maps to the platform-engineering role

| Responsibility | Where it lives |
|---|---|
| Azure + Kubernetes infra design | `modules/networking`, `modules/aks-cluster` |
| Scalable/secure/reliable IaC | Zonal pools, private cluster, Entra RBAC, validated variables |
| Release/deploy/**upgrade** tooling | `.azuredevops/` pipeline; `automatic_channel_upgrade` + maintenance window; [`docs/runbook-upgrades.md`](docs/runbook-upgrades.md) |
| Observability as code | `modules/observability-datadog` (monitors, SLO, dashboard) |
| Security / compliance / governance | deny-default NSG, Defender, `modules/governance`, tfsec + checkov + OPA in CI |
| Cost monitoring & optimization | `modules/cost-management`, infracost gate, [`docs/cost-optimization.md`](docs/cost-optimization.md) |
| Dev/ops liaison & continuous delivery | PR-based plan review, approval-gated apply, reusable pipeline templates, runbooks |

---

## What is intentionally out of scope

This repo is infrastructure only. Application delivery (Helm charts, K8s
manifests, GitOps/Argo/Flux) would live in a separate app repo consuming this
platform's outputs (cluster name, OIDC issuer for workload identity). That
separation is itself the recommended practice — platform and app lifecycles
differ.
