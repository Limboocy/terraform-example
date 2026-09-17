# Local developer workflow — the same gates CI runs, runnable before you push.
# Usage: make validate ENV=prod   |   make plan ENV=staging
ENV ?= dev
DIR := environments/$(ENV)

.PHONY: help fmt validate lint sec plan policy check clean

help:
	@echo "Targets: fmt validate lint sec plan policy check (ENV=dev|staging|prod)"

fmt:
	terraform fmt -recursive

validate:
	cd $(DIR) && terraform init -backend=false && terraform validate

lint:
	tflint --recursive

sec:
	tfsec . --minimum-severity HIGH
	checkov -d . --config-file .checkov.yaml

plan:
	cd $(DIR) && terraform init && terraform plan -out=tfplan

# OPA policy check against a produced plan.
policy: plan
	cd $(DIR) && terraform show -json tfplan > plan.json
	conftest test $(DIR)/plan.json --policy policy/opa

# Everything CI runs, in order. Run this before opening a PR.
check: fmt validate lint sec

clean:
	find . -type d -name ".terraform" -prune -exec rm -rf {} \;
	find . -type f \( -name "tfplan" -o -name "plan.json" -o -name "plan.txt" \) -delete
