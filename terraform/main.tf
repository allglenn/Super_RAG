# Super_RAG V1 - Main Terraform Configuration

locals {
  common_labels = merge(var.labels, {
    environment = var.environment
  })
}

# IAM Module - Service Accounts and Permissions
module "iam" {
  source = "./modules/iam"

  project_id = var.project_id
  region     = var.region
  labels     = local.common_labels
}

# Storage Module - GCS Buckets
module "storage" {
  source = "./modules/storage"

  project_id          = var.project_id
  region              = var.region
  bucket_name         = var.documents_bucket_name
  lifecycle_age_days  = var.bucket_lifecycle_age_days
  labels              = local.common_labels
}

# Vertex AI Module - RAG Corpora
module "vertex_ai" {
  source = "./modules/vertex-ai"

  project_id      = var.project_id
  region          = var.region
  corpora_config  = var.corpora_config
  embedding_model = var.embedding_model
  chunk_size      = var.chunk_size
  chunk_overlap   = var.chunk_overlap
  labels          = local.common_labels

  depends_on = [module.storage]
}

# Cloud Run Module - Application Services
module "cloud_run" {
  source = "./modules/cloud-run"

  project_id                = var.project_id
  region                    = var.region
  rag_ingestor_config       = var.rag_ingestor_config
  adk_agent_config          = var.adk_agent_config
  docker_image_rag_ingestor = var.docker_image_rag_ingestor
  docker_image_adk_agent    = var.docker_image_adk_agent
  rag_ingestor_sa_email     = module.iam.rag_ingestor_sa_email
  adk_agent_sa_email        = module.iam.adk_agent_sa_email
  labels                    = local.common_labels

  # Environment variables
  legal_corpus_name     = module.vertex_ai.legal_corpus_name
  technical_corpus_name = module.vertex_ai.technical_corpus_name
  training_corpus_name  = module.vertex_ai.training_corpus_name
  documents_bucket_name = module.storage.bucket_name
  gemini_model          = var.gemini_model
  top_k_chunks          = var.top_k_chunks

  depends_on = [module.iam, module.vertex_ai]
}

# Eventarc Module - Event Triggers
module "eventarc" {
  source = "./modules/eventarc"

  project_id             = var.project_id
  region                 = var.region
  documents_bucket_name  = module.storage.bucket_name
  rag_ingestor_url       = module.cloud_run.rag_ingestor_url
  eventarc_trigger_sa    = module.iam.eventarc_trigger_sa_email
  labels                 = local.common_labels

  depends_on = [module.cloud_run, module.storage]
}
