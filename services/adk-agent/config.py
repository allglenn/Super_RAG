"""Configuration management for adk-agent service."""

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

    # AI Model Configuration
    gemini_model: str = os.getenv("GEMINI_MODEL", "gemini-1.5-pro")

    # RAG Configuration
    top_k_chunks: int = int(os.getenv("TOP_K_CHUNKS", "5"))
    similarity_threshold: float = float(os.getenv("SIMILARITY_THRESHOLD", "0.5"))

    # Server Configuration
    port: int = int(os.getenv("PORT", "8080"))
    log_level: str = os.getenv("LOG_LEVEL", "INFO")

    class Config:
        """Pydantic configuration."""
        case_sensitive = False


# Global settings instance
settings = Settings()
