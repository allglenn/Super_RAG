"""RAG Ingestor Service - Processes documents uploaded to GCS via Eventarc."""

import logging
import sys
from typing import Dict, Any
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
import uvicorn

from config import settings
from corpus_mapper import CorpusMapper
from vertex_client import VertexRAGClient

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper()),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="RAG Ingestor Service",
    description="Processes documents uploaded to GCS and indexes them in Vertex AI RAG",
    version="1.0.0",
)

# Initialize services
corpus_mapper = CorpusMapper()
vertex_client = VertexRAGClient()


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "rag-ingestor"}


@app.post("/")
async def handle_eventarc_event(request: Request):
    """
    Handle Eventarc events for GCS object finalize.

    Expected CloudEvent format from Eventarc:
    {
        "type": "google.cloud.storage.object.v1.finalized",
        "source": "//storage.googleapis.com/buckets/BUCKET_NAME",
        "subject": "objects/OBJECT_NAME",
        "id": "...",
        "time": "...",
        "datacontenttype": "application/json",
        "data": {
            "bucket": "BUCKET_NAME",
            "name": "OBJECT_NAME",
            "contentType": "...",
            ...
        }
    }
    """
    try:
        # Parse the CloudEvent
        event_data = await request.json()
        logger.info(f"Received Eventarc event: {event_data.get('type')}")

        # Extract GCS object information
        data = event_data.get("data", {})
        bucket_name = data.get("bucket")
        object_name = data.get("name")
        content_type = data.get("contentType", "")

        if not bucket_name or not object_name:
            logger.error("Missing bucket or object name in event data")
            raise HTTPException(status_code=400, detail="Invalid event data")

        # Skip if it's a folder placeholder (.keep files)
        if object_name.endswith("/.keep") or object_name.endswith(".keep"):
            logger.info(f"Skipping placeholder file: {object_name}")
            return {"status": "skipped", "reason": "placeholder file"}

        logger.info(f"Processing file: gs://{bucket_name}/{object_name}")

        # Determine the corpus based on the folder path
        corpus_name = corpus_mapper.get_corpus_name(object_name)
        if not corpus_name:
            logger.warning(f"No corpus mapping for object: {object_name}")
            return {
                "status": "skipped",
                "reason": "no corpus mapping",
                "object": object_name,
            }

        # Construct GCS URI
        gcs_uri = f"gs://{bucket_name}/{object_name}"

        # Extract display name from object path
        display_name = object_name.split("/")[-1]

        # Import the document to Vertex AI RAG
        success = await vertex_client.import_document(
            corpus_name=corpus_name,
            gcs_uri=gcs_uri,
            display_name=display_name,
        )

        if success:
            logger.info(f"Successfully processed document: {display_name}")
            return {
                "status": "success",
                "corpus": corpus_name,
                "document": display_name,
                "gcs_uri": gcs_uri,
            }
        else:
            logger.error(f"Failed to process document: {display_name}")
            raise HTTPException(status_code=500, detail="Document import failed")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing Eventarc event: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "error": str(exc)},
    )


if __name__ == "__main__":
    logger.info(f"Starting RAG Ingestor service on port {settings.port}")
    logger.info(f"Project: {settings.gcp_project_id}, Region: {settings.gcp_region}")
    logger.info(f"Documents bucket: {settings.documents_bucket}")

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=settings.port,
        log_level=settings.log_level.lower(),
    )
