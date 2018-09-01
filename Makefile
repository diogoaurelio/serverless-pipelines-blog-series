######################################################################################
#### 					Terraform Makefile						                  ####
######################################################################################

.ONESHELL:
SHELL := /bin/bash

BUCKETKEY = $(ENVIRONMENT)
CUR_DIR = $(PWD)

build-redshift-lambda:
	@cd etl/lambda/redshift && bash build.sh

redshift-lambda: build-redshift-lambda
	@cd $(CUR_DIR) \
	&& make apply \
	&& cd etl/lambda/redshift && rm -rf lambda.zip


build-all-lambdas: build-redshift-lambda

init:
	@cd terraform/environments/$(ENVIRONMENT) && terraform init

update:
	@cd terraform/environments/$(ENVIRONMENT) && terraform get -update=true 1>/dev/null


plan-lambdas: init update build-all-lambdas
	@cd terraform/environments/$(ENVIRONMENT) && terraform plan \
		-input=false \
		-refresh=true \
		-module-depth=-1 \
		-var-file=$(ENVIRONMENT).tfvars

plan: init update
	@cd terraform/environments/$(ENVIRONMENT) && terraform plan \
		-input=false \
		-refresh=true \
		-module-depth=-1 \
		-var-file=$(ENVIRONMENT).tfvars

plan-destroy: init update
	@cd terraform/environments/$(ENVIRONMENT) && terraform plan \
		-input=false \
		-refresh=true \
		-module-depth=-1 \
		-destroy \
		-var-file=$(ENVIRONMENT).tfvars

show: init
	@cd terraform/environments/$(ENVIRONMENT) && terraform show -module-depth=-1


apply-lambdas: init update build-all-lambdas
	@cd terraform/environments/$(ENVIRONMENT) && terraform apply \
		-input=true \
		-refresh=true \
		-var-file=$(ENVIRONMENT).tfvars

apply: init update
	@cd terraform/environments/$(ENVIRONMENT) && terraform apply \
		-input=true \
		-refresh=true \
		-var-file=$(ENVIRONMENT).tfvars


apply-auto-approve: init update
	@cd terraform/environments/$(ENVIRONMENT) && terraform apply \
		-auto-approve \
		-input=true \
		-refresh=true \
		-var-file=$(ENVIRONMENT).tfvars

destroy: init update
	@cd terraform/environments/$(ENVIRONMENT) && terraform destroy \
		-var-file=$(ENVIRONMENT).tfvars

clean:
	@cd terraform/environments/$(ENVIRONMENT) && rm -fR .terraform/modules







