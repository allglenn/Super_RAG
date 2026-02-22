"""Corpus mapping logic for determining which corpus to use based on folder path."""

import logging
from typing import Optional
from config import settings

logger = logging.getLogger(__name__)


class CorpusMapper:
    """Maps GCS folder paths to Vertex AI RAG corpus names."""

    def __init__(self):
        """Initialize the corpus mapper with configured corpus names."""
        self.folder_to_corpus = {
            "legal/": settings.legal_corpus_name,
            "technical/": settings.technical_corpus_name,
            "training/": settings.training_corpus_name,
        }

    def get_corpus_name(self, gcs_path: str) -> Optional[str]:
        """
        Determine the corpus name based on the GCS object path.

        Args:
            gcs_path: Full GCS path of the object (e.g., "legal/doc.pdf")

        Returns:
            Corpus name if path matches a known folder, None otherwise
        """
        for folder, corpus_name in self.folder_to_corpus.items():
            if gcs_path.startswith(folder):
                logger.info(f"Mapped path '{gcs_path}' to corpus '{corpus_name}'")
                return corpus_name

        logger.warning(f"No corpus mapping found for path: {gcs_path}")
        return None

    def get_folder_from_path(self, gcs_path: str) -> Optional[str]:
        """
        Extract the folder name from a GCS path.

        Args:
            gcs_path: Full GCS path of the object

        Returns:
            Folder name if found, None otherwise
        """
        for folder in self.folder_to_corpus.keys():
            if gcs_path.startswith(folder):
                return folder.rstrip("/")
        return None
