# Cloud Run Module - RAG Services

# Cloud Run Service - rag-ingestor
resource "google_cloud_run_v2_service" "rag_ingestor" {
  name     = "rag-ingestor"
  location = var.region
  project  = var.project_id

  template {
    service_account = var.rag_ingestor_sa_email

    scaling {
      min_instance_count = var.rag_ingestor_config.min_instances
      max_instance_count = var.rag_ingestor_config.max_instances
    }

    timeout = "${var.rag_ingestor_config.timeout_seconds}s"

    containers {
      image = var.docker_image_rag_ingestor

      resources {
        limits = {
          cpu    = var.rag_ingestor_config.cpu
          memory = var.rag_ingestor_config.memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "GCP_PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "GCP_REGION"
        value = var.region
      }

      env {
        name  = "LEGAL_CORPUS_NAME"
        value = var.legal_corpus_name
      }

      env {
        name  = "TECHNICAL_CORPUS_NAME"
        value = var.technical_corpus_name
      }

      env {
        name  = "TRAINING_CORPUS_NAME"
        value = var.training_corpus_name
      }

      env {
        name  = "DOCUMENTS_BUCKET"
        value = var.documents_bucket_name
      }

      env {
        name  = "LOG_LEVEL"
        value = "INFO"
      }

      env {
        name  = "PORT"
        value = "8080"
      }

      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 5
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 30
        failure_threshold     = 3
      }
    }

    max_instance_request_concurrency = var.rag_ingestor_config.concurrency
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  labels = var.labels
}

# IAM policy to allow Eventarc to invoke rag-ingestor (will be bound in Eventarc module)
resource "google_cloud_run_service_iam_member" "rag_ingestor_invoker" {
  service  = google_cloud_run_v2_service.rag_ingestor.name
  location = google_cloud_run_v2_service.rag_ingestor.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}

# Cloud Run Service - adk-agent
resource "google_cloud_run_v2_service" "adk_agent" {
  name     = "adk-agent"
  location = var.region
  project  = var.project_id

  template {
    service_account = var.adk_agent_sa_email

    scaling {
      min_instance_count = var.adk_agent_config.min_instances
      max_instance_count = var.adk_agent_config.max_instances
    }

    timeout = "${var.adk_agent_config.timeout_seconds}s"

    containers {
      image = var.docker_image_adk_agent

      resources {
        limits = {
          cpu    = var.adk_agent_config.cpu
          memory = var.adk_agent_config.memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "GCP_PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "GCP_REGION"
        value = var.region
      }

      env {
        name  = "LEGAL_CORPUS_NAME"
        value = var.legal_corpus_name
      }

      env {
        name  = "TECHNICAL_CORPUS_NAME"
        value = var.technical_corpus_name
      }

      env {
        name  = "TRAINING_CORPUS_NAME"
        value = var.training_corpus_name
      }

      env {
        name  = "GEMINI_MODEL"
        value = var.gemini_model
      }

      env {
        name  = "TOP_K_CHUNKS"
        value = tostring(var.top_k_chunks)
      }

      env {
        name  = "LOG_LEVEL"
        value = "INFO"
      }

      env {
        name  = "PORT"
        value = "8080"
      }

      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 5
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 30
        failure_threshold     = 3
      }
    }

    max_instance_request_concurrency = var.adk_agent_config.concurrency
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  labels = var.labels
}

# IAM policy to allow authenticated users to invoke adk-agent
resource "google_cloud_run_service_iam_member" "adk_agent_invoker" {
  service  = google_cloud_run_v2_service.adk_agent.name
  location = google_cloud_run_v2_service.adk_agent.location
  role     = "roles/run.invoker"
  member   = "allAuthenticatedUsers"
}
