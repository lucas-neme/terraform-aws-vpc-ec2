# Atalhos do projeto. "make help" lista tudo.
# Ambiente padrão: dev. Para prod: make apply ENV=prod
ENV ?= dev
TF  ?= terraform
VARS := -var-file=envs/$(ENV)/terraform.tfvars

.DEFAULT_GOAL := help
.PHONY: help up bootstrap init plan apply smoke destroy down test fmt validate lint security unit e2e

help: ## mostra esta ajuda
	@grep -E '^[a-z0-9-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-10s %s\n", $$1, $$2}'

up: ## sobe o LocalStack e cria o bucket do state (bootstrap)
	docker compose up -d --wait
	$(MAKE) bootstrap

bootstrap: ## cria o bucket S3 do state remoto
	$(TF) -chdir=bootstrap init -input=false
	$(TF) -chdir=bootstrap apply -auto-approve -input=false

init: ## terraform init com o backend do ambiente
	$(TF) init -input=false -reconfigure -backend-config=envs/$(ENV)/backend.hcl

plan: init ## mostra o que vai mudar (gera $(ENV).tfplan)
	$(TF) plan -input=false $(VARS) -out=$(ENV).tfplan

apply: plan ## aplica exatamente o plano revisado
	$(TF) apply -input=false $(ENV).tfplan

smoke: ## confere pela API do LocalStack que tudo existe
	ENV=$(ENV) ./scripts/smoke.sh

destroy: init ## destrói os recursos do ambiente
	$(TF) destroy -auto-approve -input=false $(VARS)

down: ## destrói o bucket do state e desliga o LocalStack
	-$(TF) -chdir=bootstrap destroy -auto-approve -input=false
	docker compose down -v

test: fmt validate lint security unit ## todas as verificações estáticas + testes (sem LocalStack)

fmt: ## formatação
	$(TF) fmt -check -recursive -diff

validate: ## sintaxe e tipos
	$(TF) init -backend=false -input=false
	$(TF) validate
	$(TF) -chdir=bootstrap init -backend=false -input=false
	$(TF) -chdir=bootstrap validate

lint: ## tflint (boas práticas e regras da AWS)
	tflint --init
	tflint --recursive --config "$(CURDIR)/.tflint.hcl"

security: ## checkov (más configurações de segurança)
	checkov -d . --config-file .checkov.yaml

unit: ## terraform test com provider simulado
	$(TF) test

e2e: up apply smoke destroy down ## ciclo completo no LocalStack
