variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "corpora_config" {
  description = "Configuration for RAG corpora"
  type = map(object({
    display_name = string
    description  = string
    folder_path  = string
  }))
}

variable "embedding_model" {
  description = "Vertex AI embedding model to use"
  type        = string
}

variable "chunk_size" {
  description = "Size of text chunks for RAG indexing (in tokens)"
  type        = number
}

variable "chunk_overlap" {
  description = "Overlap between chunks (in tokens)"
  type        = number
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
