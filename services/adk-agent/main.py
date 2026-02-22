"""ADK Agent Service - Handles user queries with RAG-grounded responses."""

import logging
import sys
from typing import Optional, List
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn

from config import settings
from agent import ADKAgent

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper()),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="ADK Agent Service",
    description="RAG-powered question answering service using Vertex AI and Gemini",
    version="1.0.0",
)

# Initialize the agent
agent = ADKAgent()


class QueryRequest(BaseModel):
    """Request model for query endpoint."""

    query: str
    corpus_filter: Optional[List[str]] = None
    include_citations: bool = True


class QueryResponse(BaseModel):
    """Response model for query endpoint."""

    response: str
    contexts: List[dict]
    model: str
    num_contexts_used: int
    error: Optional[str] = None


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "adk-agent"}


@app.post("/query", response_model=QueryResponse)
async def query(request: QueryRequest):
    """
    Process a user query and return a RAG-grounded response.

    Args:
        request: QueryRequest with user's question and optional parameters

    Returns:
        QueryResponse with generated answer and source contexts
    """
    try:
        if not request.query or not request.query.strip():
            raise HTTPException(status_code=400, detail="Query cannot be empty")

        logger.info(f"Received query request: {request.query[:100]}...")

        # Generate response using the agent
        result = await agent.generate_response(
            query=request.query,
            corpus_filter=request.corpus_filter,
            include_citations=request.include_citations,
        )

        return QueryResponse(**result)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing query: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/corpora")
async def list_corpora():
    """
    List available RAG corpora.

    Returns:
        List of corpus names and their configurations
    """
    return {
        "corpora": [
            {
                "name": "legal",
                "corpus_name": settings.legal_corpus_name,
                "description": "Legal documents corpus",
            },
            {
                "name": "technical",
                "corpus_name": settings.technical_corpus_name,
                "description": "Technical documents corpus",
            },
            {
                "name": "training",
                "corpus_name": settings.training_corpus_name,
                "description": "Training documents corpus",
            },
        ]
    }


@app.exception_handler(Exception)
async def global_exception_handler(request, exc: Exception):
    """Global exception handler."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "error": str(exc)},
    )


if __name__ == "__main__":
    logger.info(f"Starting ADK Agent service on port {settings.port}")
    logger.info(f"Project: {settings.gcp_project_id}, Region: {settings.gcp_region}")
    logger.info(f"Model: {settings.gemini_model}")

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=settings.port,
        log_level=settings.log_level.lower(),
    )
