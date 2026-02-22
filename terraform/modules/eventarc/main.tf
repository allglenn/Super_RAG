# Eventarc Module - GCS Event Trigger for RAG Ingestor

# Eventarc trigger for GCS object finalize events
resource "google_eventarc_trigger" "gcs_rag_ingestor" {
  name     = "gcs-rag-ingestor-trigger"
  location = var.region
  project  = var.project_id

  # Match on GCS object finalize events
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  matching_criteria {
    attribute = "bucket"
    value     = var.documents_bucket_name
  }

  # Target the rag-ingestor Cloud Run service
  destination {
    cloud_run_service {
      service = "rag-ingestor"
      region  = var.region
    }
  }

  service_account = var.eventarc_trigger_sa

  labels = var.labels
}

# Grant the Eventarc trigger service account permission to invoke Cloud Run
resource "google_cloud_run_service_iam_member" "eventarc_invoker" {
  location = var.region
  service  = "rag-ingestor"
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.eventarc_trigger_sa}"
}

# Grant the GCS service account permission to publish to Eventarc
data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

resource "google_project_iam_member" "gcs_pubsub_publishing" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}
