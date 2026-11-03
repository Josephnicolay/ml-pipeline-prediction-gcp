variable "projects" {
  description = "The three GCP projects to create, keyed by their purpose."
  type = map(object({
    project_id = string
    name       = string
  }))

  validation {
    condition = length(var.projects) == 3 && alltrue([
      for key in ["source", "process", "production"] : contains(keys(var.projects), key)
    ])
    error_message = "Project keys must be exactly source, process, and production."
  }
}

variable "parent" {
  description = "Set exactly one of organization_id or folder_id."
  type = object({
    organization_id = optional(string)
    folder_id       = optional(string)
  })

  validation {
    condition     = (var.parent.organization_id != null) != (var.parent.folder_id != null)
    error_message = "Set exactly one of parent.organization_id or parent.folder_id."
  }
}

variable "billing_account_id" {
  description = "The billing account to associate with all three projects."
  type        = string
}

variable "region" {
  description = "Location for BigQuery datasets and the artifacts bucket (for example: US, EU, us-central1)."
  type        = string
  default     = "US"
}

variable "pipeline_service_account_email" {
  description = "Pipeline runtime service account email in process project. If set and missing, Terraform creates it; if it exists, Terraform reuses it."
  type        = string
  default     = ""
}

variable "cloud_run_service_account_email" {
  description = "Cloud Run launcher service account email in process project. If set and missing, Terraform creates it; if it exists, Terraform reuses it."
  type        = string
  default     = ""
}

variable "pipeline_service_account_id" {
  description = "Fallback account ID for the pipeline runtime service account in process project when pipeline_service_account_email is empty."
  type        = string
  default     = "pipeline-runner"
}

variable "pipeline_service_account_display_name" {
  description = "Display name for the pipeline runtime service account created by Terraform."
  type        = string
  default     = "Pipeline Runner"
}

variable "cloud_run_service_account_id" {
  description = "Fallback account ID for the Cloud Run launcher service account in process project when cloud_run_service_account_email is empty."
  type        = string
  default     = "cloud-run"
}

variable "cloud_run_service_account_display_name" {
  description = "Display name for the Cloud Run launcher service account created by Terraform."
  type        = string
  default     = "Cloud Run Launcher"
}

variable "artifact_registry_repository_id" {
  description = "Artifact Registry Docker repository ID for process images."
  type        = string
  default     = "test"
}

variable "artifact_registry_location" {
  description = "Artifact Registry location for process images (for example: us-central1)."
  type        = string
  default     = "us-central1"
}

variable "source_input_table_id" {
  description = "Input table ID to create in the source BigQuery dataset."
  type        = string
  default     = "input_table"
}