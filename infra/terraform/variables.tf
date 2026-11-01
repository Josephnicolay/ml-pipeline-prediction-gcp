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
  description = "Service account email used by the pipeline runtime. Leave empty to skip IAM bindings."
  type        = string
  default     = ""
}