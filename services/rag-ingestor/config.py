"""Configuration management for rag-ingestor service."""

import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # GCP Configuration
    gcp_project_id: str = os.getenv("GCP_PROJECT_ID", "")
    gcp_region: str = os.getenv("GCP_REGION", "us-central1")

    # Vertex AI RAG Corpus Names
    legal_corpus_name: str = os.getenv("LEGAL_CORPUS_NAME", "")
    technical_corpus_name: str = os.getenv("TECHNICAL_CORPUS_NAME", "")
    training_corpus_name: str = os.getenv("TRAINING_CORPUS_NAME", "")

    # Storage Configuration
    documents_bucket: str = os.getenv("DOCUMENTS_BUCKET", "")

    # RAG Configuration
    embedding_model: str = os.getenv("EMBEDDING_MODEL", "text-embedding-004")
    chunk_size: int = int(os.getenv("CHUNK_SIZE", "1000"))
    chunk_overlap: int = int(os.getenv("CHUNK_OVERLAP", "200"))

    # Server Configuration
    port: int = int(os.getenv("PORT", "8080"))
    log_level: str = os.getenv("LOG_LEVEL", "INFO")

    class Config:
        """Pydantic configuration."""
        case_sensitive = False


# Global settings instance
settings = Settings()
