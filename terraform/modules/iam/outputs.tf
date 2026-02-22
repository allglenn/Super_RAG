output "rag_ingestor_sa_email" {
  description = "Email of the rag-ingestor service account"
  value       = google_service_account.rag_ingestor.email
}

output "rag_ingestor_sa_name" {
  description = "Name of the rag-ingestor service account"
  value       = google_service_account.rag_ingestor.name
}

output "adk_agent_sa_email" {
  description = "Email of the adk-agent service account"
  value       = google_service_account.adk_agent.email
}

output "adk_agent_sa_name" {
  description = "Name of the adk-agent service account"
  value       = google_service_account.adk_agent.name
}

output "eventarc_trigger_sa_email" {
  description = "Email of the eventarc-trigger service account"
  value       = google_service_account.eventarc_trigger.email
}

output "eventarc_trigger_sa_name" {
  description = "Name of the eventarc-trigger service account"
  value       = google_service_account.eventarc_trigger.name
}
