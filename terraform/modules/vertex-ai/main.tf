# Vertex AI Module - RAG Corpora Configuration

# Note: As of early 2024, Terraform support for Vertex AI RAG API is limited.
# This module uses google-beta provider for resources that may not be fully GA.
# If resources are not available via Terraform, you may need to create them via:
# 1. gcloud CLI commands
# 2. Python SDK during application deployment
# 3. Google Cloud Console

# For now, we'll create a configuration that can be referenced by the application
# The actual corpus creation will happen via the Python SDK in the rag-ingestor service

locals {
  # Generate corpus names that will be created via SDK
  legal_corpus_name     = "projects/${var.project_id}/locations/${var.region}/ragCorpora/${var.project_id}-legal-corpus"
  technical_corpus_name = "projects/${var.project_id}/locations/${var.region}/ragCorpora/${var.project_id}-technical-corpus"
  training_corpus_name  = "projects/${var.project_id}/locations/${var.region}/ragCorpora/${var.project_id}-training-corpus"
}

# If Vertex AI RAG Corpus resource becomes available in Terraform, uncomment and modify:
#
# resource "google_vertex_ai_rag_corpus" "legal" {
#   provider     = google-beta
#   name         = "${var.project_id}-legal-corpus"
#   display_name = var.corpora_config.legal.display_name
#   description  = var.corpora_config.legal.description
#   project      = var.project_id
#   location     = var.region
#
#   rag_embedding_model_config {
#     vertex_prediction_endpoint {
#       endpoint = "projects/${var.project_id}/locations/${var.region}/publishers/google/models/${var.embedding_model}"
#     }
#   }
# }

# For now, we output the expected corpus names for use by the application
