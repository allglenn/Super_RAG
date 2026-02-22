# IAM Module - Service Accounts and Permissions

# Service Account for rag-ingestor
resource "google_service_account" "rag_ingestor" {
  account_id   = "rag-ingestor"
  display_name = "RAG Ingestor Service Account"
  description  = "Service account for the RAG document ingestor Cloud Run service"
  project      = var.project_id
}

# Service Account for adk-agent
resource "google_service_account" "adk_agent" {
  account_id   = "adk-agent"
  display_name = "ADK Agent Service Account"
  description  = "Service account for the ADK agent Cloud Run service"
  project      = var.project_id
}

# Service Account for Eventarc trigger
resource "google_service_account" "eventarc_trigger" {
  account_id   = "eventarc-trigger"
  display_name = "Eventarc Trigger Service Account"
  description  = "Service account for Eventarc triggers"
  project      = var.project_id
}

# IAM Bindings for rag-ingestor
resource "google_project_iam_member" "rag_ingestor_aiplatform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.rag_ingestor.email}"
}

resource "google_project_iam_member" "rag_ingestor_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.rag_ingestor.email}"
}

resource "google_project_iam_member" "rag_ingestor_logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.rag_ingestor.email}"
}

# IAM Bindings for adk-agent
resource "google_project_iam_member" "adk_agent_aiplatform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.adk_agent.email}"
}

resource "google_project_iam_member" "adk_agent_logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.adk_agent.email}"
}

# IAM Bindings for Eventarc trigger
resource "google_project_iam_member" "eventarc_event_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.eventarc_trigger.email}"
}

# Grant Eventarc service account permission to invoke rag-ingestor Cloud Run
# This will be set up in the Cloud Run module with IAM policy binding
