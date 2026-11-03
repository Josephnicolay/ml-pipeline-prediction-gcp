SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

.PHONY: help data pipeline image job test schedule all

help:
	@echo "Targets:"
	@echo "  make data      - Load initial data into BigQuery"
	@echo "  make pipeline  - Compile pipeline and upload JSON to GCS"
	@echo "  make image     - Build container image with Cloud Build"
	@echo "  make job       - Deploy Cloud Run Job"
	@echo "  make test      - Execute Cloud Run Job once"
	@echo "  make schedule  - Create or update Cloud Scheduler job"
	@echo "  make all       - Run all steps in order"
	@echo ""
	@echo "Optional: ENV_FILE=/path/to/.env.deploy make all"

data:
	@./scripts/data_load.sh

pipeline:
	@./scripts/pipeline_compile_upload.sh

image:
	@./scripts/image_build.sh

job:
	@./scripts/job_deploy.sh

test:
	@./scripts/job_run_test.sh

schedule:
	@./scripts/scheduler_apply.sh

all: data pipeline image job test schedule
