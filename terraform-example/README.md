# infra — Azure/AKS Terraform

## Layout

```
infra/
├── environments/          # one state per environment, thin — just wiring
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/                # reusable, environment-agnostic logic
│   ├── networking/          # VNet, subnets, NSGs
│   ├── aks-cluster/         # AKS cluster + node pools
│   └── datadog-monitors/    # monitors-as-code
└── README.md
```

## Design rules this repo follows

1. **Environments call modules, they don't contain logic.** All the real
   resource definitions live in `modules/`. `environments/*/main.tf` just
   wires module inputs together with environment-specific values.
2. **Separate state per environment.** dev/staging/prod each have their own
   `backend.tf` pointing at a different key in the same Azure Storage
   container. Never share state across environments — a bad `apply` in dev
   should not be able to touch prod's state file.
3. **No secrets in `.tfvars` committed to git.** Real values (client secrets,
   Datadog API keys) are injected via environment variables or a secrets
   backend (Azure Key Vault data source), never hardcoded.
4. **Plan before apply, always.** CI runs `terraform plan` on every PR and
   posts the plan as a comment. `apply` only runs after manual approval on
   `main`, and only for the environment whose files changed.
5. **State locking is mandatory.** Azure Storage backend supports native
   locking — if you see a "state locked" error, do not force-unlock without
   confirming no one else is mid-apply.

## Workflow

```bash
cd environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Never run `terraform apply` without a saved plan reviewed first. Never run
`terraform destroy` against staging or prod without a second person
confirming.
