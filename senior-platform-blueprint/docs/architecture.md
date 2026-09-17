# Architecture & Design Decisions

Records the *why* behind the structure so the tradeoffs are reviewable.

## Composition model: root-per-environment
Each `environments/<env>` is a thin composition root that calls shared modules
with env-specific inputs. State is isolated per environment.

- **Why not workspaces?** Terraform workspaces share one backend key and one
  provider config; a fat-finger in one workspace can touch another. Separate
  root dirs give hard blast-radius isolation and let prod pin different provider
  behavior if needed.
- **Cost of this choice:** some duplication across the three root `main.tf`
  files. Accepted deliberately — the duplication is inputs, not logic (logic is
  in modules), and the isolation is worth it. At larger scale, Terragrunt or a
  code-gen layer removes the duplication without losing isolation.

## Module boundaries
Modules are split by **lifecycle and ownership**, not by resource type:
- `networking` changes rarely and is security-sensitive.
- `aks-cluster` changes on version upgrades and scaling.
- `observability-datadog` changes when SLOs/alerts evolve — often, and by a
  different reviewer set.

Splitting by lifecycle means a noisy-but-safe change (tuning an alert threshold)
never sits in the same plan as a risky one (rotating a subnet).

## Security posture
- **Identity:** SystemAssigned managed identity + workload identity (OIDC). No
  static service-principal secrets anywhere.
- **Network:** private API server (stg/prod), deny-default NSG, separate subnet
  for private endpoints to PaaS.
- **Data:** state in a GRS storage account with key-auth disabled (Entra only),
  versioning + 30-day soft delete.
- **Defence in depth:** Azure Policy add-on + Microsoft Defender on-cluster;
  tfsec/checkov/OPA in the pipeline before anything is applied.

## Delivery model
Plan is produced once and published as an artifact; the approved artifact is the
exact thing applied. Approval gates are ADO Environments (audit trail + required
reviewers). This is what makes "approved == deployed" a guarantee rather than a
hope.

## Known simplifications in this blueprint (call-outs for real use)
- No hub-spoke / firewall egress (`outbound_type = loadBalancer`). Real prod
  often uses `userDefinedRouting` through an Azure Firewall hub.
- Private DNS uses the AKS-managed `System` zone; a shared private DNS zone is
  common at scale.
- No ACR, Key Vault, or ingress controller module — they'd attach via the
  private-endpoint subnet and kubelet identity that are already provisioned.
- Single region. DR to a second region would reuse every module with a new
  backend key.
