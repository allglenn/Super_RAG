output "trigger_name" {
  description = "Name of the Eventarc trigger"
  value       = google_eventarc_trigger.gcs_rag_ingestor.name
}

output "trigger_id" {
  description = "ID of the Eventarc trigger"
  value       = google_eventarc_trigger.gcs_rag_ingestor.id
}
