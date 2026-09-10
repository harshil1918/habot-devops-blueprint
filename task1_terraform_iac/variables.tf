# =============================================================================
# Task 1 - Input variables
# Author: Harshil Parmar | Contact: harshilparmar1907@gmil.com | +91 9824624715
# =============================================================================

variable "project_id" {
  description = "Target GCP project ID for the staging environment."
  type        = string
}

variable "project_number" {
  description = "Numeric GCP project number, used to reference Google-managed service agents for CMEK."
  type        = string
}

variable "region" {
  description = "Deployment region for all regional resources."
  type        = string
  default     = "europe-west1"
}

variable "name_prefix" {
  description = "Lowercase prefix applied to every resource name for consistent, collision-free naming."
  type        = string
  default     = "habot-staging"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.name_prefix))
    error_message = "name_prefix must be lowercase alphanumeric with hyphens, 3 to 21 characters, starting with a letter."
  }
}

variable "data_owner_group" {
  description = "Google Group email that owns the D1 dataset. A group, never a personal account (Least Privilege)."
  type        = string
}

variable "analyst_reader_group" {
  description = "Google Group email granted read-only access to the D1 dataset."
  type        = string
}
