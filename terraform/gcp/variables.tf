variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "GCP Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "region" {
  description = "GCP region for Cloud Run deployment"
  type        = string
  default     = "europe-southwest1"
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "cyber-analyzer"
}

variable "openai_api_key" {
  description = "OpenAI API key for the application"
  type        = string
  sensitive   = true
  default     = ""
}

variable "semgrep_app_token" {
  description = "Semgrep app token for security scanning"
  type        = string
  sensitive   = true
  default     = ""
}

variable "docker_image_tag" {
  description = "Tag for the Docker image"
  type        = string
  default     = "latest"
}
