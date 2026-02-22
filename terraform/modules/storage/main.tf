# Storage Module - GCS Bucket for RAG Documents

resource "google_storage_bucket" "documents" {
  name          = var.bucket_name
  location      = var.region
  project       = var.project_id
  storage_class = "STANDARD"

  uniform_bucket_level_access {
    enabled = true
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = var.lifecycle_age_days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  labels = var.labels

  # Prevent accidental deletion
  force_destroy = false
}

# Create folder structure within the bucket
# Note: GCS doesn't have true folders, these are just placeholder objects
resource "google_storage_bucket_object" "legal_folder" {
  name    = "legal/.keep"
  content = "Placeholder for legal documents folder"
  bucket  = google_storage_bucket.documents.name
}

resource "google_storage_bucket_object" "technical_folder" {
  name    = "technical/.keep"
  content = "Placeholder for technical documents folder"
  bucket  = google_storage_bucket.documents.name
}

resource "google_storage_bucket_object" "training_folder" {
  name    = "training/.keep"
  content = "Placeholder for training documents folder"
  bucket  = google_storage_bucket.documents.name
}
