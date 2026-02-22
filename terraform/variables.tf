variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, staging)"
  type        = string
  default     = "prod"
}

# Storage Configuration
variable "documents_bucket_name" {
  description = "Name of the GCS bucket for storing documents"
  type        = string
}

variable "bucket_lifecycle_age_days" {
  description = "Number of days before moving objects to Nearline storage"
  type        = number
  default     = 90
}

# Vertex AI Configuration
variable "embedding_model" {
  description = "Vertex AI embedding model to use"
  type        = string
  default     = "text-embedding-004"
}

variable "gemini_model" {
  description = "Gemini model to use for generation"
  type        = string
  default     = "gemini-1.5-pro"
}

variable "chunk_size" {
  description = "Size of text chunks for RAG indexing (in tokens)"
  type        = number
  default     = 1000
}

variable "chunk_overlap" {
  description = "Overlap between chunks (in tokens)"
  type        = number
  default     = 200
}

variable "top_k_chunks" {
  description = "Number of top chunks to retrieve for RAG"
  type        = number
  default     = 5
}

# Corpus Configuration
variable "corpora_config" {
  description = "Configuration for RAG corpora"
  type = map(object({
    display_name = string
    description  = string
    folder_path  = string
  }))
  default = {
    legal = {
      display_name = "Legal Documents Corpus"
      description  = "Corpus for legal domain documents"
      folder_path  = "legal/"
    }
    technical = {
      display_name = "Technical Documents Corpus"
      description  = "Corpus for technical domain documents"
      folder_path  = "technical/"
    }
    training = {
      display_name = "Training Documents Corpus"
      description  = "Corpus for training domain documents"
      folder_path  = "training/"
    }
  }
}

# Cloud Run Configuration
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
  default = {
    cpu              = "2"
    memory           = "4Gi"
    max_instances    = 10
    min_instances    = 0
    timeout_seconds  = 3600
    concurrency      = 1
  }
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
  default = {
    cpu              = "2"
    memory           = "2Gi"
    max_instances    = 5
    min_instances    = 1
    timeout_seconds  = 300
    concurrency      = 80
  }
}

# Docker Image Configuration
variable "docker_image_rag_ingestor" {
  description = "Docker image for rag-ingestor service"
  type        = string
  default     = "gcr.io/cloudrun/hello" # Placeholder, will be replaced by Cloud Build
}

variable "docker_image_adk_agent" {
  description = "Docker image for adk-agent service"
  type        = string
  default     = "gcr.io/cloudrun/hello" # Placeholder, will be replaced by Cloud Build
}

# Tagging
variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    application = "super-rag"
    version     = "v1"
    managed_by  = "terraform"
  }
}
