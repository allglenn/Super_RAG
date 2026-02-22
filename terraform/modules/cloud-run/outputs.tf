output "rag_ingestor_url" {
  description = "URL of the rag-ingestor Cloud Run service"
  value       = google_cloud_run_v2_service.rag_ingestor.uri
}

output "rag_ingestor_name" {
  description = "Name of the rag-ingestor Cloud Run service"
  value       = google_cloud_run_v2_service.rag_ingestor.name
}

output "adk_agent_url" {
  description = "URL of the adk-agent Cloud Run service"
  value       = google_cloud_run_v2_service.adk_agent.uri
}

output "adk_agent_name" {
  description = "Name of the adk-agent Cloud Run service"
  value       = google_cloud_run_v2_service.adk_agent.name
}
