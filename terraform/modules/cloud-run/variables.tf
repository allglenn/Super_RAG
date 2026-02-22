variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "rag_ingestor_config" {
  description = "Configuration for rag-ingestor Cloud Run service"
  type = object({
    cpu              = string
    memory           = string
    max_instances    = number
    min_instances    = number
    timeout_seconds  = number
    concurrency      = number
  })
}

variable "adk_agent_config" {
  description = "Configuration for adk-agent Cloud Run service"
  type = object({
    cpu              = string
    memory           = string
    max_instances    = number
    min_instances    = number
    timeout_seconds  = number
    concurrency      = number
  })
}

variable "docker_image_rag_ingestor" {
  description = "Docker image for rag-ingestor service"
  type        = string
}

variable "docker_image_adk_agent" {
  description = "Docker image for adk-agent service"
  type        = string
}

variable "rag_ingestor_sa_email" {
  description = "Service account email for rag-ingestor"
  type        = string
}

variable "adk_agent_sa_email" {
  description = "Service account email for adk-agent"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

# Environment variables
variable "legal_corpus_name" {
  description = "Resource name of the legal corpus"
  type        = string
}

variable "technical_corpus_name" {
  description = "Resource name of the technical corpus"
  type        = string
}

variable "training_corpus_name" {
  description = "Resource name of the training corpus"
  type        = string
}

variable "documents_bucket_name" {
  description = "Name of the documents bucket"
  type        = string
}

variable "gemini_model" {
  description = "Gemini model to use"
  type        = string
}

variable "top_k_chunks" {
  description = "Number of top chunks to retrieve"
  type        = number
}
