# Super_RAG V1 - Document-Based RAG System

A production-ready Retrieval-Augmented Generation (RAG) system built on Google Cloud Platform that processes documents uploaded to GCS buckets, creates vector embeddings using Vertex AI, and provides intelligent query responses through a Gemini-powered agent.

## Architecture Overview

```
User uploads file → GCS bucket (legal/, technical/, training/)
                           ↓
              Eventarc trigger (Object Finalize)
                           ↓
              Cloud Run (rag-ingestor)
                           ↓
              Vertex AI RAG Engine → Parse, chunk, embed
                           ↓
              Managed Vector Index
                           ↓
User query → Cloud Run (adk-agent) → Retrieves context → Gemini generates response
```

**📊 Detailed Architecture Diagrams**: See [Architecture Documentation](docs/architecture-diagram.md) for comprehensive Mermaid diagrams including:
- System architecture with data flow
- Component interactions
- Security & IAM topology
- CI/CD pipeline flow
- Infrastructure dependencies
- Cost breakdown

For in-depth technical details, see [Detailed Architecture Guide](docs/architecture-detailed.md).

## Technology Stack

- **Infrastructure**: Terraform
- **CI/CD**: Google Cloud Build
- **Language**: Python 3.11
- **Services**:
  - Cloud Run (rag-ingestor, adk-agent)
  - Cloud Storage
  - Eventarc
  - Vertex AI (RAG Engine, Gemini)
  - Artifact Registry

## Features

- Automated document ingestion on GCS upload
- Multiple domain-specific corpora (legal, technical, training)
- RAG-powered question answering with Gemini
- Scalable Cloud Run architecture
- Infrastructure as Code with Terraform
- Automated CI/CD with Cloud Build
- Comprehensive logging and monitoring

## Prerequisites

- GCP Project with billing enabled
- gcloud CLI installed and configured
- Terraform >= 1.5.0 installed
- Docker installed (for local development)
- Python 3.11+ (for local development)

## Quick Start

### 1. Set Up GCP Project

```bash
# Set your project ID
export GCP_PROJECT_ID="your-gcp-project-id"
export GCP_REGION="us-central1"

# Run the setup script to enable APIs
chmod +x scripts/setup-gcp-project.sh
./scripts/setup-gcp-project.sh
```

### 2. Create Terraform Backend

```bash
# Create GCS bucket for Terraform state
chmod +x scripts/create-tf-backend.sh
./scripts/create-tf-backend.sh
```

### 3. Configure Terraform

```bash
cd terraform

# Copy and edit the variables file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project details

# Update backend.tf with your state bucket name
sed -i '' "s/YOUR_PROJECT_ID/$GCP_PROJECT_ID/g" backend.tf
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

### 5. Build and Deploy Services

#### Option A: Using Cloud Build (Recommended)

Set up Cloud Build triggers in GCP Console or use gcloud:

```bash
# Deploy rag-ingestor
gcloud builds submit --config=cloudbuild/cloudbuild-ingestor.yaml

# Deploy adk-agent
gcloud builds submit --config=cloudbuild/cloudbuild-agent.yaml
```

#### Option B: Manual Deployment

```bash
# Build and deploy rag-ingestor
cd services/rag-ingestor
gcloud builds submit --tag ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/rag-docker-repo/rag-ingestor
gcloud run deploy rag-ingestor \
  --image ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/rag-docker-repo/rag-ingestor \
  --region ${GCP_REGION}

# Build and deploy adk-agent
cd ../adk-agent
gcloud builds submit --tag ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/rag-docker-repo/adk-agent
gcloud run deploy adk-agent \
  --image ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/rag-docker-repo/adk-agent \
  --region ${GCP_REGION}
```

## Usage

### Upload Documents

Upload documents to the appropriate GCS folder:

```bash
# Upload a legal document
gsutil cp contract.pdf gs://${GCP_PROJECT_ID}-rag-documents/legal/

# Upload a technical document
gsutil cp technical-spec.pdf gs://${GCP_PROJECT_ID}-rag-documents/technical/

# Upload a training document
gsutil cp training-guide.pdf gs://${GCP_PROJECT_ID}-rag-documents/training/
```

The rag-ingestor service will automatically process the document and index it in Vertex AI RAG.

### Query the Agent

```bash
# Get the adk-agent URL
ADK_AGENT_URL=$(gcloud run services describe adk-agent \
  --region ${GCP_REGION} \
  --format 'value(status.url)')

# Send a query
curl -X POST ${ADK_AGENT_URL}/query \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What are the key points in the contract?",
    "include_citations": true
  }'
```

### List Available Corpora

```bash
curl ${ADK_AGENT_URL}/corpora \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)"
```

## Project Structure

```
simple_rag/
├── services/
│   ├── rag-ingestor/          # Document ingestion service
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── corpus_mapper.py
│   │   ├── vertex_client.py
│   │   ├── requirements.txt
│   │   └── Dockerfile
│   └── adk-agent/             # Query answering service
│       ├── main.py
│       ├── config.py
│       ├── agent.py
│       ├── rag_retriever.py
│       ├── requirements.txt
│       └── Dockerfile
├── terraform/                  # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── storage/
│       ├── iam/
│       ├── vertex-ai/
│       ├── cloud-run/
│       └── eventarc/
├── cloudbuild/                # CI/CD configurations
│   ├── cloudbuild-ingestor.yaml
│   ├── cloudbuild-agent.yaml
│   └── cloudbuild-terraform.yaml
├── scripts/                   # Setup scripts
│   ├── setup-gcp-project.sh
│   └── create-tf-backend.sh
├── .env.example
├── .gitignore
└── README.md
```

## Local Development

### Running rag-ingestor Locally

```bash
cd services/rag-ingestor

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"
export LEGAL_CORPUS_NAME="projects/.../legal-corpus"
# ... other environment variables

# Run the service
python main.py
```

### Running adk-agent Locally

```bash
cd services/adk-agent

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"
# ... other environment variables

# Run the service
python main.py
```

## Monitoring and Logging

### View Cloud Run Logs

```bash
# rag-ingestor logs
gcloud run services logs read rag-ingestor --region ${GCP_REGION}

# adk-agent logs
gcloud run services logs read adk-agent --region ${GCP_REGION}
```

### Check Service Health

```bash
# rag-ingestor health
RAG_INGESTOR_URL=$(gcloud run services describe rag-ingestor --region ${GCP_REGION} --format 'value(status.url)')
curl ${RAG_INGESTOR_URL}/health

# adk-agent health
curl ${ADK_AGENT_URL}/health
```

### Monitor Eventarc Triggers

```bash
gcloud eventarc triggers describe gcs-rag-ingestor-trigger --location ${GCP_REGION}
```

## Creating RAG Corpora

The Vertex AI RAG corpora need to be created before ingesting documents. You can create them using the Vertex AI SDK:

```python
from google.cloud.aiplatform import rag

# Create legal corpus
legal_corpus = rag.create_corpus(
    display_name="Legal Documents Corpus",
    description="Corpus for legal domain documents"
)

# Create technical corpus
technical_corpus = rag.create_corpus(
    display_name="Technical Documents Corpus",
    description="Corpus for technical domain documents"
)

# Create training corpus
training_corpus = rag.create_corpus(
    display_name="Training Documents Corpus",
    description="Corpus for training domain documents"
)
```

Or use the gcloud CLI (if available):

```bash
# Note: Exact commands may vary based on Vertex AI RAG API availability
gcloud ai rag-corpora create legal-corpus \
  --display-name="Legal Documents Corpus" \
  --region=${GCP_REGION}
```

## Troubleshooting

### Corpus Not Found Error

If you see "Corpus not found" errors, create the RAG corpora as described above and update the corpus names in your environment variables.

### Permission Denied

Ensure service accounts have the correct IAM roles:
- `rag-ingestor`: `roles/aiplatform.user`, `roles/storage.objectViewer`
- `adk-agent`: `roles/aiplatform.user`

### Eventarc Not Triggering

1. Check if GCS service account has `pubsub.publisher` role
2. Verify the trigger is active: `gcloud eventarc triggers list --location ${GCP_REGION}`
3. Check logs: `gcloud logging read "resource.type=cloud_run_revision"`

## Cost Optimization

- rag-ingestor: Scales to zero when idle (min_instances = 0)
- adk-agent: Runs 1 instance minimum for low latency (configurable)
- Storage lifecycle: Moves documents to Nearline after 90 days
- Set budget alerts in GCP Console

**Estimated Monthly Cost**: $165-470 (varies based on usage)

## Security Considerations

- All Cloud Run services use dedicated service accounts with least privilege
- IAM authentication required for API access
- Uniform bucket-level access on GCS
- No sensitive data in environment variables (use Secret Manager for secrets)
- Cloud Run ingress: rag-ingestor (internal only), adk-agent (authenticated)

## CI/CD Pipeline

The project includes Cloud Build configurations for automated deployments:

1. **Code Push** → Cloud Build Trigger
2. **Run Tests** → Build Docker Image
3. **Push to Artifact Registry** → Deploy to Cloud Run
4. **Health Check Verification**

Set up triggers in Cloud Build console to automatically deploy on push to `main` branch.

## Contributing

1. Make changes in a feature branch
2. Test locally using Docker
3. Submit PR with descriptive commit messages
4. Ensure Terraform fmt is run: `terraform fmt -recursive`

## License

[Specify your license]

## Support

For issues and questions:
- Check the troubleshooting section above
- Review Cloud Run logs
- Check Terraform state for infrastructure issues

