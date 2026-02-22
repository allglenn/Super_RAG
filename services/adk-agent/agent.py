"""ADK Agent for generating responses with RAG-grounded context."""

import logging
from typing import Dict, Any, List, Optional
import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig
from config import settings
from rag_retriever import RAGRetriever

logger = logging.getLogger(__name__)


class ADKAgent:
    """Agent that uses Gemini with RAG-retrieved context to answer queries."""

    def __init__(self):
        """Initialize the ADK agent."""
        vertexai.init(project=settings.gcp_project_id, location=settings.gcp_region)

        self.model = GenerativeModel(settings.gemini_model)
        self.retriever = RAGRetriever()

        self.generation_config = GenerationConfig(
            temperature=0.2,  # Lower temperature for more factual responses
            top_p=0.95,
            top_k=40,
            max_output_tokens=2048,
        )

        logger.info(f"Initialized ADK Agent with model: {settings.gemini_model}")

    async def generate_response(
        self,
        query: str,
        corpus_filter: Optional[List[str]] = None,
        include_citations: bool = True,
    ) -> Dict[str, Any]:
        """
        Generate a response to a user query using RAG-grounded context.

        Args:
            query: User's question
            corpus_filter: Optional list of specific corpora to search
            include_citations: Whether to include source citations in response

        Returns:
            Dictionary with response text, contexts, and metadata
        """
        try:
            logger.info(f"Processing query: '{query}'")

            # Step 1: Retrieve relevant contexts from RAG
            contexts = await self.retriever.retrieve_contexts(
                query=query,
                corpus_filter=corpus_filter,
            )

            if not contexts:
                logger.warning("No contexts retrieved for query")
                return {
                    "response": "I don't have enough information to answer that question based on the available documents.",
                    "contexts": [],
                    "model": settings.gemini_model,
                }

            # Step 2: Format contexts for the prompt
            formatted_contexts = self.retriever.format_contexts_for_prompt(contexts)

            # Step 3: Construct the prompt with grounded context
            prompt = self._construct_prompt(query, formatted_contexts, include_citations)

            # Step 4: Generate response with Gemini
            logger.info("Generating response with Gemini")
            response = self.model.generate_content(
                prompt,
                generation_config=self.generation_config,
            )

            response_text = response.text if hasattr(response, "text") else str(response)

            logger.info("Successfully generated response")

            return {
                "response": response_text,
                "contexts": contexts,
                "model": settings.gemini_model,
                "num_contexts_used": len(contexts),
            }

        except Exception as e:
            logger.error(f"Error generating response: {e}", exc_info=True)
            return {
                "response": f"Error generating response: {str(e)}",
                "contexts": [],
                "model": settings.gemini_model,
                "error": str(e),
            }

    def _construct_prompt(
        self, query: str, contexts: str, include_citations: bool
    ) -> str:
        """
        Construct the prompt for Gemini with grounded context.

        Args:
            query: User's question
            contexts: Formatted context string
            include_citations: Whether to request citations

        Returns:
            Complete prompt string
        """
        citation_instruction = (
            "\n\nWhen providing information from the context, cite the source documents."
            if include_citations
            else ""
        )

        prompt = f"""You are a helpful AI assistant that answers questions based on the provided context.

Context from documents:
{contexts}

Instructions:
- Answer the user's question based ONLY on the information provided in the context above
- If the context doesn't contain relevant information to answer the question, say so
- Be concise but comprehensive
- Use a professional and helpful tone{citation_instruction}

User Question: {query}

Answer:"""

        return prompt
