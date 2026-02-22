variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "documents_bucket_name" {
  description = "Name of the documents bucket to watch"
  type        = string
}

variable "rag_ingestor_url" {
  description = "URL of the rag-ingestor Cloud Run service"
  type        = string
}

variable "eventarc_trigger_sa" {
  description = "Service account email for Eventarc trigger"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
