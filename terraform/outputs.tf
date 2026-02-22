# Super_RAG V1 - Terraform Outputs

# Storage Outputs
output "documents_bucket_name" {
  description = "Name of the GCS bucket for documents"
  value       = module.storage.bucket_name
}

output "documents_bucket_url" {
  description = "URL of the GCS bucket for documents"
  value       = module.storage.bucket_url
}

# IAM Outputs
output "rag_ingestor_service_account" {
  description = "Service account email for rag-ingestor"
  value       = module.iam.rag_ingestor_sa_email
}

output "adk_agent_service_account" {
  description = "Service account email for adk-agent"
  value       = module.iam.adk_agent_sa_email
}

output "eventarc_trigger_service_account" {
  description = "Service account email for Eventarc trigger"
  value       = module.iam.eventarc_trigger_sa_email
}

# Vertex AI Outputs
output "legal_corpus_name" {
  description = "Resource name of the legal corpus"
  value       = module.vertex_ai.legal_corpus_name
}

output "technical_corpus_name" {
  description = "Resource name of the technical corpus"
  value       = module.vertex_ai.technical_corpus_name
}

output "training_corpus_name" {
  description = "Resource name of the training corpus"
  value       = module.vertex_ai.training_corpus_name
}

# Cloud Run Outputs
output "rag_ingestor_url" {
  description = "URL of the rag-ingestor Cloud Run service"
  value       = module.cloud_run.rag_ingestor_url
}

output "adk_agent_url" {
  description = "URL of the adk-agent Cloud Run service"
  value       = module.cloud_run.adk_agent_url
}

# Eventarc Outputs
output "eventarc_trigger_name" {
  description = "Name of the Eventarc trigger"
  value       = module.eventarc.trigger_name
}

# Quick Start Information
output "next_steps" {
  description = "Next steps after Terraform deployment"
  value = <<-EOT
    Infrastructure deployed successfully!

    Next steps:
    1. Upload test documents to: gs://${module.storage.bucket_name}/legal/
    2. Check Cloud Run logs: gcloud run services logs read rag-ingestor --project=${var.project_id}
    3. Query the agent:
       curl -X POST ${module.cloud_run.adk_agent_url}/query \
         -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
         -H "Content-Type: application/json" \
         -d '{"query": "Your question here"}'

    Service URLs:
    - RAG Ingestor: ${module.cloud_run.rag_ingestor_url}
    - ADK Agent: ${module.cloud_run.adk_agent_url}
  EOT
}
