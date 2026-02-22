"""RAG retrieval logic for querying Vertex AI RAG corpora."""

import logging
from typing import List, Dict, Any, Optional
from google.cloud import aiplatform
from google.cloud.aiplatform import rag
from google.api_core import exceptions
from config import settings

logger = logging.getLogger(__name__)


class RAGRetriever:
    """Retriever for querying Vertex AI RAG corpora."""

    def __init__(self):
        """Initialize the RAG retriever."""
        aiplatform.init(project=settings.gcp_project_id, location=settings.gcp_region)
        self.corpora = [
            settings.legal_corpus_name,
            settings.technical_corpus_name,
            settings.training_corpus_name,
        ]
        logger.info(f"Initialized RAG Retriever with {len(self.corpora)} corpora")

    async def retrieve_contexts(
        self,
        query: str,
        corpus_filter: Optional[List[str]] = None,
        top_k: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Retrieve relevant contexts from RAG corpora.

        Args:
            query: User query string
            corpus_filter: Optional list of corpus names to search (defaults to all)
            top_k: Number of top chunks to retrieve (defaults to settings)

        Returns:
            List of retrieved contexts with text and metadata
        """
        if top_k is None:
            top_k = settings.top_k_chunks

        # Determine which corpora to search
        corpora_to_search = corpus_filter if corpus_filter else self.corpora

        try:
            logger.info(f"Retrieving contexts for query: '{query}' from {len(corpora_to_search)} corpora")

            # Retrieve relevant contexts from all specified corpora
            response = rag.retrieval_query(
                rag_resources=[
                    rag.RagResource(rag_corpus=corpus_name)
                    for corpus_name in corpora_to_search
                ],
                text=query,
                similarity_top_k=top_k,
            )

            # Parse and format the results
            contexts = []
            if hasattr(response, "contexts") and response.contexts:
                for idx, context in enumerate(response.contexts.contexts):
                    contexts.append({
                        "rank": idx + 1,
                        "text": context.text,
                        "source": context.source_uri if hasattr(context, "source_uri") else "unknown",
                        "distance": context.distance if hasattr(context, "distance") else None,
                    })

            logger.info(f"Retrieved {len(contexts)} contexts for query")
            return contexts

        except exceptions.NotFound as e:
            logger.error(f"One or more corpora not found: {e}")
            return []

        except exceptions.InvalidArgument as e:
            logger.error(f"Invalid argument in retrieval query: {e}")
            return []

        except Exception as e:
            logger.error(f"Error during RAG retrieval: {e}", exc_info=True)
            return []

    def format_contexts_for_prompt(self, contexts: List[Dict[str, Any]]) -> str:
        """
        Format retrieved contexts into a string for the prompt.

        Args:
            contexts: List of context dictionaries

        Returns:
            Formatted context string
        """
        if not contexts:
            return "No relevant context found."

        formatted = "Retrieved Context:\n\n"
        for ctx in contexts:
            formatted += f"[Source: {ctx['source']}]\n{ctx['text']}\n\n"

        return formatted
