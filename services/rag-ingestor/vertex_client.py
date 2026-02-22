"""Vertex AI RAG API client for importing documents."""

import logging
from typing import Optional
from google.cloud import aiplatform
from google.cloud.aiplatform import rag
from google.api_core import exceptions
from tenacity import retry, stop_after_attempt, wait_exponential
from config import settings

logger = logging.getLogger(__name__)


class VertexRAGClient:
    """Client for interacting with Vertex AI RAG API."""

    def __init__(self):
        """Initialize the Vertex AI RAG client."""
        aiplatform.init(project=settings.gcp_project_id, location=settings.gcp_region)
        logger.info(
            f"Initialized Vertex AI RAG client for project {settings.gcp_project_id} "
            f"in region {settings.gcp_region}"
        )

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=4, max=10),
        reraise=True,
    )
    async def import_document(
        self, corpus_name: str, gcs_uri: str, display_name: str
    ) -> bool:
        """
        Import a document into a Vertex AI RAG corpus.

        Args:
            corpus_name: Full resource name of the RAG corpus
            gcs_uri: GCS URI of the document (e.g., gs://bucket/path/file.pdf)
            display_name: Display name for the document

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Importing document '{display_name}' from {gcs_uri} to corpus {corpus_name}")

            # Import files to the corpus
            response = rag.import_files(
                corpus_name=corpus_name,
                paths=[gcs_uri],
                chunk_size=settings.chunk_size,
                chunk_overlap=settings.chunk_overlap,
            )

            logger.info(
                f"Successfully imported document '{display_name}' "
                f"(imported {response.imported_rag_files_count} files)"
            )
            return True

        except exceptions.NotFound as e:
            logger.error(f"Corpus not found: {corpus_name}. Error: {e}")
            logger.info("You may need to create the corpus first. See README for instructions.")
            return False

        except exceptions.InvalidArgument as e:
            logger.error(f"Invalid argument when importing document: {e}")
            return False

        except exceptions.GoogleAPIError as e:
            logger.error(f"Google API error during document import: {e}")
            raise

        except Exception as e:
            logger.error(f"Unexpected error during document import: {e}", exc_info=True)
            raise

    async def ensure_corpus_exists(self, corpus_name: str, display_name: str) -> bool:
        """
        Ensure a RAG corpus exists, create it if it doesn't.

        Args:
            corpus_name: Full resource name of the RAG corpus
            display_name: Display name for the corpus

        Returns:
            True if corpus exists or was created, False otherwise
        """
        try:
            # Try to get the corpus
            corpus = rag.get_corpus(name=corpus_name)
            logger.info(f"Corpus '{corpus_name}' already exists")
            return True

        except exceptions.NotFound:
            # Corpus doesn't exist, create it
            try:
                logger.info(f"Creating new corpus: {display_name}")
                corpus = rag.create_corpus(
                    display_name=display_name,
                    description=f"RAG corpus for {display_name}",
                )
                logger.info(f"Successfully created corpus: {corpus.name}")
                return True

            except Exception as e:
                logger.error(f"Failed to create corpus: {e}", exc_info=True)
                return False

        except Exception as e:
            logger.error(f"Error checking corpus existence: {e}", exc_info=True)
            return False
