SHELL := /bin/bash --login

.PHONY: init validate fmt plan apply destroy

help:
	@echo "Piksel-Hub Terraform Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  init     - Initialize Terraform"
	@echo "  validate - Validate configuration"
	@echo "  fmt      - Format all .tf files"
	@echo "  plan     - Show planned changes"
	@echo "  apply    - Apply changes"
	@echo "  destroy  - Destroy resources"

dir ?= deployments

init:
	@echo "Initializing $(dir)..."
	terraform -chdir=$(dir) init

validate:
	@echo "Validating $(dir)..."
	terraform -chdir=$(dir) validate

fmt:
	@echo "Formatting ..."
	terraform fmt -recursive

plan:
	@echo "Planning $(dir)..."
	terraform -chdir=$(dir) plan

apply:
	@echo "Applying $(dir)..."
	terraform -chdir=$(dir) apply
	@echo  ==============================
	@echo "Backing up state..."
	@cd $(dir) && bash backup.sh run

destroy:
	@echo "Destroying $(dir)..."
	terraform -chdir=$(dir) destroy
