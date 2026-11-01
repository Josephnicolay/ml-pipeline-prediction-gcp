# ML Pipeline Prediction on GCP

## Overview

This project provisions foundational Google Cloud Platform (GCP) infrastructure for a planned housing-price prediction pipeline. Terraform creates the projects, BigQuery datasets, Cloud Storage bucket, enables required APIs, and configures permissions. 

## Architecture

The diagram shows the planned architecture for the end-to-end machine learning pipeline.

<img src="imgs/Proyecto_Final.png" alt="Project Architecture" width="600">

#### Project components

The planned design uses the following components:

*GCP projects:*
- `source`: Intended for raw housing data in BigQuery.
- `process`: Intended for data processing, model training, and artifact storage.
- `production`: Intended for production datasets and predictions.

The projects separate data ingestion, processing, and production responsibilities.

*BigQuery datasets:*
- `bq_housing_source`: Dataset provisioned for raw housing data.
- `bq_housing_process`: Dataset provisioned for processed training data.
- `bq_housing_prod`: Dataset provisioned for production data and predictions.

*Cloud Storage buckets:*
- `<process-project-id>-artifacts`: Bucket provisioned for pipeline artifacts.

*Planned Vertex AI pipeline:*
- Will orchestrate data processing and predictions from the pretrained model.

*Planned Cloud Run Job:*
- Will invoke the compiled pipeline to serve predictions.

*Planned Cloud Scheduler:*
- Will trigger the Vertex AI pipeline and Cloud Run Job at specified intervals.

*Pipeline service account:*
- Terraform grants the configured service account the permissions listed below. The account itself is not created by this configuration.

## Infrastructure Setup (Terraform)

### Step by step
1. Authenticate in GCP:
```bash
gcloud auth application-default login
```
2. Go to Terraform folder:
```bash
cd infra/terraform
```
3. Copy and edit variables:
```bash
cp terraform.tfvars.example terraform.tfvars
```
4. Initialize Terraform:
```bash
terraform init
```
5. Validate configuration:
```bash
terraform validate
```
6. Create and review plan:
```bash
terraform plan -out=tfplan
```
7. Apply resources:
```bash
terraform apply tfplan
```

### What gets created
- 3 GCP projects: `source`, `process`, `production`
- Required APIs per project (BigQuery in all; Storage, Vertex AI, Cloud Run, Cloud Scheduler in `process`)
- 3 BigQuery datasets:
	- `bq_housing_source`
	- `bq_housing_process`
	- `bq_housing_prod`
- 1 GCS bucket in `process`, named `<process-project-id>-artifacts`

### Permissions (pipeline service account)
- In `source`: `roles/bigquery.dataViewer`
- In `process`: `roles/bigquery.dataEditor`, `roles/bigquery.jobUser`
- In `production`: `roles/bigquery.dataEditor`
- On artifacts bucket: `roles/storage.objectViewer`
