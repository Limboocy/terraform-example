# Runbook: AKS Cluster Upgrades

Covers the "manage upgrade processes across environments" responsibility. Two
upgrade tracks run here: **automatic patch** (unattended, low-risk) and
**minor version** (attended, promoted through environments).

## 1. Patch upgrades (automatic)

Configured in the module via `automatic_channel_upgrade = "patch"` and a
`maintenance_window_auto_upgrade` (Sundays 02:00 UTC, 4h). AKS applies patch
releases within the current minor version during that window. No human action.

- Terraform ignores `kubernetes_version` drift (`lifecycle.ignore_changes`) so
  these auto-applied patches don't show as a "downgrade" plan.
- Verify after the window: `az aks show -g <rg> -n <cluster> --query kubernetesVersion`.

## 2. Minor version upgrades (attended, promoted)

Minor upgrades (e.g. 1.29 → 1.30) are deliberate and flow dev → staging → prod.

### Pre-flight
1. Check the [AKS release calendar] and your version's support window.
2. Review breaking changes / deprecated APIs (`kubectl` deprecations, removed
   admission controllers). Run `kubent` (kube-no-trouble) against each cluster.
3. Confirm add-on / CSI driver / ingress controller compatibility with the target.

### Procedure (per environment, starting with dev)
1. Bump `kubernetes_version` default in `modules/aks-cluster/variables.tf`
   **or** pass it per-env. Open a PR.
2. Pipeline runs plan. Because control plane and node pools upgrade separately,
   expect the plan to update the control plane first.
3. Merge → approve the `Apply` gate for **dev only**.
4. Soak: watch the Datadog AKS dashboard + CrashLoop/CPU monitors for the soak
   period (dev: 1h, staging: 24h). Node pools surge-upgrade at `max_surge = 33%`.
5. Promote to staging, soak, then prod. Prod approval requires a second reviewer.

### Node image vs. control plane
Control plane and node pools are versioned independently. After a control-plane
minor bump, node pools are upgraded pool-by-pool with surge nodes so capacity is
never reduced during the roll.

## 3. Rollback

Kubernetes does **not** support in-place downgrade of a cluster. "Rollback"
options, in order of preference:
1. **Roll forward** to a fixed patch — usually the fastest safe path.
2. For node-level issues: cordon/drain the bad pool, scale up a new pool on the
   prior node image, migrate workloads, delete the bad pool.
3. Blue/green cluster (worst case): stand up a parallel cluster at the old
   version via a second env workspace and shift traffic at the ingress/DNS layer.

Because state is per-environment and the modules are parameterized, standing up a
parallel cluster is a `terraform apply` with a new `key` in the backend, not a
manual rebuild.

## 4. Comms (dev/ops liaison)
- Announce the maintenance window in `#devops-alerts-<env>` 24h ahead.
- Every alert carries a `runbook_url` back to this doc.
- Post-upgrade: confirm SLO burn is nominal before closing the change ticket.

[AKS release calendar]: https://learn.microsoft.com/azure/aks/supported-kubernetes-versions
