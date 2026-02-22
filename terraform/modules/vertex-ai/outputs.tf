output "legal_corpus_name" {
  description = "Resource name of the legal corpus"
  value       = local.legal_corpus_name
}

output "technical_corpus_name" {
  description = "Resource name of the technical corpus"
  value       = local.technical_corpus_name
}

output "training_corpus_name" {
  description = "Resource name of the training corpus"
  value       = local.training_corpus_name
}

output "corpus_config" {
  description = "Configuration for all corpora"
  value = {
    legal = {
      name         = local.legal_corpus_name
      display_name = var.corpora_config.legal.display_name
      description  = var.corpora_config.legal.description
      folder_path  = var.corpora_config.legal.folder_path
    }
    technical = {
      name         = local.technical_corpus_name
      display_name = var.corpora_config.technical.display_name
      description  = var.corpora_config.technical.description
      folder_path  = var.corpora_config.technical.folder_path
    }
    training = {
      name         = local.training_corpus_name
      display_name = var.corpora_config.training.display_name
      description  = var.corpora_config.training.description
      folder_path  = var.corpora_config.training.folder_path
    }
  }
}

output "embedding_model" {
  description = "Embedding model being used"
  value       = var.embedding_model
}

output "chunk_config" {
  description = "Chunk configuration for RAG"
  value = {
    size    = var.chunk_size
    overlap = var.chunk_overlap
  }
}
