resource "google_project" "projects" {
  for_each = var.projects

  project_id      = each.value.project_id
  name            = each.value.name
  org_id          = var.parent.organization_id
  folder_id       = var.parent.folder_id
  billing_account = var.billing_account_id
  deletion_policy = "PREVENT"
}

locals {
  services_by_project = {
    source = [
      "bigquery.googleapis.com",
    ]
    process = [
      "bigquery.googleapis.com",
      "storage.googleapis.com",
      "run.googleapis.com",
      "cloudscheduler.googleapis.com",
      "aiplatform.googleapis.com",
    ]
    production = [
      "bigquery.googleapis.com",
    ]
  }

  project_service_bindings = {
    for binding in flatten([
      for project_key, services in local.services_by_project : [
        for service in services : {
          key         = "${project_key}/${service}"
          project_key = project_key
          service     = service
        }
      ]
    ]) : binding.key => binding
  }

  datasets_by_project = {
    source     = "bq_housing_source"
    process    = "bq_housing_process"
    production = "bq_housing_prod"
  }

  pipeline_sa_enabled      = var.pipeline_service_account_email != ""
  cloud_run_sa_enabled     = var.cloud_run_service_account_email != ""
  launcher_bindings_enabled = local.pipeline_sa_enabled && local.cloud_run_sa_enabled

  pipeline_sa_member      = "serviceAccount:${var.pipeline_service_account_email}"
  cloud_run_sa_member     = "serviceAccount:${var.cloud_run_service_account_email}"
  pipeline_sa_project_id  = split(".", split("@", var.pipeline_service_account_email)[1])[0]
}

resource "google_project_service" "services" {
  for_each = local.project_service_bindings

  project            = google_project.projects[each.value.project_key].project_id
  service            = each.value.service
  disable_on_destroy = false
}

resource "google_bigquery_dataset" "datasets" {
  for_each = local.datasets_by_project

  project    = google_project.projects[each.key].project_id
  dataset_id = each.value
  location   = var.region

  depends_on = [google_project_service.services]
}

resource "google_storage_bucket" "process_artifacts" {
  project = google_project.projects["process"].project_id
  name    = "${google_project.projects["process"].project_id}-artifacts"

  location                    = var.region
  uniform_bucket_level_access = true

  depends_on = [google_project_service.services]
}

resource "google_bigquery_dataset_iam_member" "source_read_access" {
  count = local.pipeline_sa_enabled ? 1 : 0

  project    = google_bigquery_dataset.datasets["source"].project
  dataset_id = google_bigquery_dataset.datasets["source"].dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = local.pipeline_sa_member
}

resource "google_bigquery_dataset_iam_member" "production_write_access" {
  count = local.pipeline_sa_enabled ? 1 : 0

  project    = google_bigquery_dataset.datasets["production"].project
  dataset_id = google_bigquery_dataset.datasets["production"].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = local.pipeline_sa_member
}

resource "google_bigquery_dataset_iam_member" "process_read_write_access" {
  count = local.pipeline_sa_enabled ? 1 : 0

  project    = google_bigquery_dataset.datasets["process"].project
  dataset_id = google_bigquery_dataset.datasets["process"].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = local.pipeline_sa_member
}

resource "google_project_iam_member" "process_query_job_access" {
  count = local.pipeline_sa_enabled ? 1 : 0

  project = google_project.projects["process"].project_id
  role    = "roles/bigquery.jobUser"
  member  = local.pipeline_sa_member
}

resource "google_storage_bucket_iam_member" "process_artifacts_read_access" {
  count = local.pipeline_sa_enabled ? 1 : 0

  bucket = google_storage_bucket.process_artifacts.name
  role   = "roles/storage.objectViewer"
  member = local.pipeline_sa_member
}

resource "google_project_iam_member" "cloud_run_vertex_ai_submit_access" {
  count = local.cloud_run_sa_enabled ? 1 : 0

  project = google_project.projects["process"].project_id
  role    = "roles/aiplatform.user"
  member  = local.cloud_run_sa_member
}

resource "google_storage_bucket_iam_member" "cloud_run_artifacts_read_access" {
  count = local.cloud_run_sa_enabled ? 1 : 0

  bucket = google_storage_bucket.process_artifacts.name
  role   = "roles/storage.objectViewer"
  member = local.cloud_run_sa_member
}

resource "google_service_account_iam_member" "cloud_run_can_use_pipeline_sa" {
  count = local.launcher_bindings_enabled ? 1 : 0

  service_account_id = "projects/${local.pipeline_sa_project_id}/serviceAccounts/${var.pipeline_service_account_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = local.cloud_run_sa_member
}

output "project_ids" {
  description = "Project IDs created by this configuration, keyed by purpose."
  value       = { for key, project in google_project.projects : key => project.project_id }
}