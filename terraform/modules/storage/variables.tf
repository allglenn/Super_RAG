variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket for storing documents"
  type        = string
}

variable "lifecycle_age_days" {
  description = "Number of days before moving objects to Nearline storage"
  type        = number
  default     = 90
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
