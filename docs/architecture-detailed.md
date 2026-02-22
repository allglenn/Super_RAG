# Super_RAG V1 - Detailed Architecture Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Component Architecture](#component-architecture)
3. [Network Architecture](#network-architecture)
4. [Data Architecture](#data-architecture)
5. [Security Architecture](#security-architecture)
6. [Deployment Architecture](#deployment-architecture)

---

## System Overview

### Architecture Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface Layer                      │
│  - Document Upload (gcloud, gsutil, Console)                    │
│  - Query Interface (REST API, curl, SDK)                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                       API Gateway Layer                          │
│  - Cloud Run: rag-ingestor (Internal)                          │
│  - Cloud Run: adk-agent (Authenticated)                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                     Business Logic Layer                         │
│  - Document Processing & Mapping                                │
│  - RAG Retrieval & Context Formatting                           │
│  - Response Generation with Citations                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      AI/ML Services Layer                        │
│  - Vertex AI RAG Engine (Document Processing)                   │
│  - Embedding Generation (text-embedding-004)                    │
│  - Vector Search (Managed Index)                                │
│  - Gemini (Response Generation)                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                       Data Storage Layer                         │
│  - Cloud Storage (Source Documents)                             │
│  - Vector Database (Embeddings + Metadata)                      │
│  - Cloud Logging (Application Logs)                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                          │
│  - Terraform (IaC)                                              │
│  - Cloud Build (CI/CD)                                          │
│  - IAM (Security)                                               │
│  - Monitoring & Alerting                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Architecture

### 1. Document Ingestion Pipeline

```
┌──────────────┐
│    User      │
│   Uploads    │
│  Document    │
└──────┬───────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│           Cloud Storage Bucket                      │
│  ┌─────────────────────────────────────────┐       │
│  │  legal/         (Legal Documents)       │       │
│  │  technical/     (Technical Docs)        │       │
│  │  training/      (Training Materials)    │       │
│  └─────────────────────────────────────────┘       │
└──────────────────┬──────────────────────────────────┘
                   │ Object Finalize Event
                   ▼
┌─────────────────────────────────────────────────────┐
│              Eventarc Trigger                       │
│  Event Type: google.cloud.storage.object.v1.finalized
│  Filter: bucket = rag-documents                     │
└──────────────────┬──────────────────────────────────┘
                   │ CloudEvent
                   ▼
┌─────────────────────────────────────────────────────┐
│         Cloud Run: rag-ingestor                     │
│  ┌───────────────────────────────────────────┐     │
│  │  1. Receive CloudEvent                    │     │
│  │  2. Extract bucket/object name            │     │
│  │  3. Map folder → corpus                   │     │
│  │     legal/     → legal-corpus             │     │
│  │     technical/ → technical-corpus         │     │
│  │     training/  → training-corpus          │     │
│  │  4. Call Vertex AI RAG API                │     │
│  └───────────────────────────────────────────┘     │
└──────────────────┬──────────────────────────────────┘
                   │ import_files()
                   ▼
┌─────────────────────────────────────────────────────┐
│          Vertex AI RAG Engine                       │
│  ┌───────────────────────────────────────────┐     │
│  │  1. Download document from GCS            │     │
│  │  2. Parse document (PDF, DOC, TXT)        │     │
│  │  3. Extract text content                  │     │
│  │  4. Chunk text (1000 tokens, 200 overlap) │     │
│  │  5. Generate embeddings (768 dimensions)  │     │
│  │  6. Store in vector index with metadata   │     │
│  └───────────────────────────────────────────┘     │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│           Managed Vector Index                      │
│  ┌───────────────────────────────────────────┐     │
│  │  Corpus: legal-corpus                     │     │
│  │  Corpus: technical-corpus                 │     │
│  │  Corpus: training-corpus                  │     │
│  │                                            │     │
│  │  Each contains:                            │     │
│  │  - Document chunks (text)                  │     │
│  │  - Embeddings (vectors)                    │     │
│  │  - Metadata (source, page, etc.)           │     │
│  └───────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────┘
```

### 2. Query Processing Pipeline

```
┌──────────────┐
│    User      │
│   Submits    │
│    Query     │
└──────┬───────┘
       │ POST /query
       ▼
┌─────────────────────────────────────────────────────┐
│          Cloud Run: adk-agent                       │
│  ┌───────────────────────────────────────────┐     │
│  │  Endpoint: POST /query                    │     │
│  │  Request:                                  │     │
│  │  {                                         │     │
│  │    "query": "What are key contract terms?",│    │
│  │    "corpus_filter": ["legal"],            │     │
│  │    "include_citations": true              │     │
│  │  }                                         │     │
│  └───────────────────────────────────────────┘     │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│           RAG Retriever Component                   │
│  ┌───────────────────────────────────────────┐     │
│  │  1. Parse query                            │     │
│  │  2. Determine corpora to search            │     │
│  │  3. Call Vertex AI retrieval_query()       │     │
│  │  4. Specify similarity_top_k = 5           │     │
│  └───────────────────────────────────────────┘     │
└──────────────────┬──────────────────────────────────┘
                   │ retrieval_query()
                   ▼
┌─────────────────────────────────────────────────────┐
│           Vector Index Search                       │
│  ┌───────────────────────────────────────────┐     │
│  │  1. Generate query embedding               │     │
│  │  2. Perform vector similarity search       │     │
│  │     (Cosine similarity)                    │     │
│  │  3. Rank results by distance               │     │
│  │  4. Return top-K chunks with metadata      │     │
│  └───────────────────────────────────────────┘     │
└──────────────────┬──────────────────────────────────┘
                   │ Contexts (text + metadata)
                   ▼
┌─────────────────────────────────────────────────────┐
│           ADK Agent Component                       │
│  ┌───────────────────────────────────────────┐     │
│  │  1. Receive retrieved contexts             │     │
│  │  2. Format contexts for prompt:            │     │
│  │     [Source: doc.pdf]                      │     │
│  │     <context text>                         │     │
│  │  3. Construct grounded prompt              │     │
│  │  4. Call Gemini API                        │     │
│  └───────────────────────────────────────────┘     │
└──────────────────┬──────────────────────────────────┘
                   │ generate_content()
                   ▼
┌─────────────────────────────────────────────────────┐
│              Gemini Model                           │
│  ┌───────────────────────────────────────────┐     │
│  │  Model: gemini-1.5-pro                     │     │
│  │  Config:                                   │     │
│  │    - temperature: 0.2 (factual)            │     │
│  │    - top_p: 0.95                           │     │
│  │    - top_k: 40                             │     │
│  │    - max_output_tokens: 2048               │     │
│  │                                            │     │
│  │  Generates response based on:              │     │
│  │  - Retrieved contexts                      │     │
│  │  - User query                              │     │
│  │  - System instructions                     │     │
│  └───────────────────────────────────────────┘     │
└──────────────────┬──────────────────────────────────┘
                   │ Response Text
                   ▼
┌─────────────────────────────────────────────────────┐
│         Format Response with Citations             │
│  ┌───────────────────────────────────────────┐     │
│  │  {                                         │     │
│  │    "response": "The key contract terms...",│    │
│  │    "contexts": [                           │     │
│  │      {                                     │     │
│  │        "rank": 1,                          │     │
│  │        "text": "...",                      │     │
│  │        "source": "gs://.../contract.pdf",  │     │
│  │        "distance": 0.12                    │     │
│  │      }                                     │     │
│  │    ],                                      │     │
│  │    "model": "gemini-1.5-pro",              │     │
│  │    "num_contexts_used": 5                  │     │
│  │  }                                         │     │
│  └───────────────────────────────────────────┘     │
└──────────────────┬──────────────────────────────────┘
                   │ JSON Response
                   ▼
              ┌────────────┐
              │    User    │
              │  Receives  │
              │  Answer    │
              └────────────┘
```

---

## Network Architecture

### Service Communication

```
┌─────────────────────────────────────────────────────────────┐
│                    Public Internet                          │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ HTTPS (Authenticated)
                 ▼
┌─────────────────────────────────────────────────────────────┐
│              Cloud Load Balancer (Managed)                  │
└────────────────┬────────────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
┌──────────────┐  ┌──────────────────┐
│ rag-ingestor │  │   adk-agent      │
│ (Internal)   │  │ (Authenticated)  │
│              │  │                  │
│ Ingress:     │  │ Ingress:         │
│ - Eventarc   │  │ - All Authed     │
│   (internal) │  │   Users          │
└──────┬───────┘  └─────────┬────────┘
       │                    │
       │    ┌───────────────┘
       │    │
       │    │ API Calls (Authenticated via Workload Identity)
       ▼    ▼
┌─────────────────────────────────────────────────────────────┐
│                  Vertex AI APIs                             │
│  - RAG API (import_files, retrieval_query)                  │
│  - Gemini API (generate_content)                            │
│  - Embedding API (text-embedding-004)                       │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ Read Objects
                 ▼
┌─────────────────────────────────────────────────────────────┐
│                 Cloud Storage API                           │
│  - Bucket: rag-documents                                    │
│  - IAM: storage.objectViewer for rag-ingestor SA            │
└─────────────────────────────────────────────────────────────┘
```

### IAM & Security Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│                    Project Boundary                          │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │           Service Account Isolation                 │    │
│  │                                                      │    │
│  │  rag-ingestor@project.iam.gserviceaccount.com      │    │
│  │  Roles:                                             │    │
│  │    ✓ aiplatform.user                                │    │
│  │    ✓ storage.objectViewer                           │    │
│  │    ✓ logging.logWriter                              │    │
│  │    ✗ NO storage write permissions                   │    │
│  │    ✗ NO network admin                               │    │
│  │                                                      │    │
│  │  adk-agent@project.iam.gserviceaccount.com         │    │
│  │  Roles:                                             │    │
│  │    ✓ aiplatform.user                                │    │
│  │    ✓ logging.logWriter                              │    │
│  │    ✗ NO storage access                              │    │
│  │    ✗ NO network admin                               │    │
│  │                                                      │    │
│  │  eventarc-trigger@project.iam.gserviceaccount.com  │    │
│  │  Roles:                                             │    │
│  │    ✓ eventarc.eventReceiver                         │    │
│  │    ✓ run.invoker (rag-ingestor only)                │    │
│  │    ✗ NO other permissions                           │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │            Network Isolation                        │    │
│  │                                                      │    │
│  │  rag-ingestor:                                      │    │
│  │    - Ingress: Internal only                         │    │
│  │    - Egress: VPC or Private Google Access           │    │
│  │    - No public IP                                   │    │
│  │                                                      │    │
│  │  adk-agent:                                         │    │
│  │    - Ingress: Authenticated users                   │    │
│  │    - Egress: VPC or Private Google Access           │    │
│  │    - Requires Bearer token                          │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Architecture

### Data Flow - Document Lifecycle

```
┌─────────────┐
│  Upload     │
│  (T0)       │
└─────┬───────┘
      │
      ▼
┌─────────────────────────────────────────┐
│ Cloud Storage (Standard Class)          │
│ - Versioning: Enabled                   │
│ - Location: Regional (us-central1)      │
│ - Encryption: Google-managed             │
└─────┬───────────────────────────────────┘
      │
      │ After T+90 days
      ▼
┌─────────────────────────────────────────┐
│ Cloud Storage (Nearline Class)          │
│ - Auto lifecycle transition              │
│ - Lower storage cost                     │
│ - Higher retrieval cost                  │
└─────┬───────────────────────────────────┘
      │
      │ Processing
      ▼
┌─────────────────────────────────────────┐
│ Vertex AI Processing                    │
│ - Parse: Extract text                   │
│ - Chunk: 1000 tokens, 200 overlap       │
│ - Embed: 768-dim vectors                 │
└─────┬───────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────┐
│ Vector Index (Permanent)                │
│                                          │
│ Document Chunk Structure:                │
│ {                                        │
│   "chunk_id": "doc123_chunk_1",          │
│   "text": "...",                         │
│   "embedding": [0.1, 0.2, ...],  // 768d │
│   "metadata": {                          │
│     "source_uri": "gs://...",            │
│     "corpus": "legal",                   │
│     "page": 1,                           │
│     "timestamp": "2024-...",             │
│     "chunk_index": 1,                    │
│     "total_chunks": 10                   │
│   }                                      │
│ }                                        │
└─────────────────────────────────────────┘
```

### Corpus Data Model

```
┌─────────────────────────────────────────────────────────────┐
│                    RAG Corpus: Legal                         │
│                                                              │
│  Corpus Name:                                               │
│    projects/PROJECT_ID/locations/us-central1/               │
│      ragCorpora/PROJECT_ID-legal-corpus                     │
│                                                              │
│  Configuration:                                             │
│    - Display Name: "Legal Documents Corpus"                 │
│    - Description: "Corpus for legal domain documents"       │
│    - Embedding Model: text-embedding-004                    │
│    - Chunk Size: 1000 tokens                                │
│    - Chunk Overlap: 200 tokens                              │
│                                                              │
│  Documents: [                                               │
│    {                                                         │
│      "name": "contract_2024.pdf",                           │
│      "gcs_uri": "gs://...-rag-documents/legal/contract...", │
│      "chunks": 15,                                          │
│      "status": "indexed"                                    │
│    },                                                        │
│    ...                                                       │
│  ]                                                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 RAG Corpus: Technical                        │
│  (Similar structure for technical documents)                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 RAG Corpus: Training                         │
│  (Similar structure for training materials)                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Security Architecture

### Defense in Depth

```
Layer 1: Network Security
├─ Cloud Run IAM Authentication
├─ Internal-only ingress (rag-ingestor)
├─ No public IP addresses
└─ VPC Service Controls (optional)

Layer 2: Identity & Access Management
├─ Dedicated service accounts per service
├─ Principle of least privilege
├─ Workload Identity Federation
└─ No service account keys

Layer 3: Data Security
├─ Encryption at rest (Google-managed keys)
├─ Encryption in transit (TLS)
├─ Uniform bucket-level access
└─ Versioning for audit trail

Layer 4: Application Security
├─ Input validation in FastAPI
├─ CloudEvent signature verification
├─ Rate limiting (Cloud Run)
└─ Health check endpoints (no auth required)

Layer 5: Monitoring & Compliance
├─ Cloud Logging (all API calls)
├─ Cloud Monitoring (metrics & alerts)
├─ Cloud Trace (distributed tracing)
└─ Audit Logs (Admin & Data Access)
```

### Secrets Management

```
┌─────────────────────────────────────────┐
│        Secret Manager                   │
│                                          │
│  Secrets:                               │
│  ├─ api-keys (if needed)                │
│  ├─ external-api-tokens                 │
│  └─ custom-config-values                │
│                                          │
│  Access Control:                        │
│  ├─ rag-ingestor: secretmanager.       │
│  │   secretAccessor (specific secrets) │
│  └─ adk-agent: secretmanager.          │
│      secretAccessor (specific secrets) │
└─────────────────────────────────────────┘
         │
         │ Accessed via environment variables
         ▼
┌─────────────────────────────────────────┐
│     Cloud Run Services                  │
│  (Secrets mounted as env vars)          │
└─────────────────────────────────────────┘
```

---

## Deployment Architecture

### Terraform State Management

```
┌─────────────────────────────────────────┐
│   Developer Workstation / CI/CD        │
└────────────┬────────────────────────────┘
             │
             │ terraform init/plan/apply
             ▼
┌─────────────────────────────────────────┐
│  GCS Bucket: terraform-state            │
│                                          │
│  State File:                            │
│    prod/terraform.tfstate               │
│                                          │
│  Features:                              │
│    ✓ Versioning enabled                 │
│    ✓ State locking (built-in)           │
│    ✓ Encryption at rest                 │
│    ✓ Access logs                        │
└────────────┬────────────────────────────┘
             │
             │ Creates/Updates
             ▼
┌─────────────────────────────────────────┐
│       GCP Infrastructure                │
│  - Storage                              │
│  - IAM                                  │
│  - Cloud Run                            │
│  - Eventarc                             │
└─────────────────────────────────────────┘
```

### CI/CD Deployment Flow

```
Developer Push to main
        │
        ▼
┌─────────────────────────────────────────┐
│     Cloud Build Triggers                │
│                                          │
│  Trigger 1: services/rag-ingestor/**    │
│  Trigger 2: services/adk-agent/**       │
│  Trigger 3: terraform/**                │
└────────────┬────────────────────────────┘
             │
             │ Execute Build
             ▼
┌─────────────────────────────────────────┐
│        Build Environment                │
│  - N1_HIGHCPU_8 machine                 │
│  - Cloud Build service account          │
│  - Timeout: 20 minutes                  │
└────────────┬────────────────────────────┘
             │
             │ Build Steps
             ▼
┌─────────────────────────────────────────┐
│   1. Run Tests (pytest)                 │
│   2. Build Docker Image                 │
│   3. Push to Artifact Registry          │
│   4. Deploy to Cloud Run                │
│   5. Health Check Verification          │
└────────────┬────────────────────────────┘
             │
             │ Deployment Complete
             ▼
┌─────────────────────────────────────────┐
│    Production Environment               │
│  - New revision deployed                │
│  - Traffic: 100% to new revision        │
│  - Old revision: Retained (rollback)    │
└─────────────────────────────────────────┘
```

### Multi-Environment Strategy (Optional Future)

```
┌────────────────────────────────────────────────────────┐
│                 Development Environment                │
│  - Project: super-rag-dev                             │
│  - Min instances: 0                                    │
│  - Budget: $50/month                                   │
└────────────────────────────────────────────────────────┘
                      ↓
            Promote after testing
                      ↓
┌────────────────────────────────────────────────────────┐
│                 Staging Environment                    │
│  - Project: super-rag-staging                         │
│  - Production-like configuration                       │
│  - Budget: $200/month                                  │
└────────────────────────────────────────────────────────┘
                      ↓
         Promote after validation
                      ↓
┌────────────────────────────────────────────────────────┐
│               Production Environment (Current)         │
│  - Project: super-rag-prod                            │
│  - Full monitoring & alerting                          │
│  - Budget: $500/month                                  │
└────────────────────────────────────────────────────────┘
```

---

## Performance & Scaling Characteristics

### Scaling Triggers

```
rag-ingestor:
  CPU Utilization > 60%  → Scale up
  Request Queue > 1      → Scale up (concurrency=1)
  No requests for 5m     → Scale to 0
  Max instances: 10

adk-agent:
  CPU Utilization > 70%  → Scale up
  Concurrent requests    → Scale up (concurrency=80)
  Always min 1 instance  → Low latency
  Max instances: 5
```

### Latency Profile

```
Document Ingestion:
  - Event trigger latency: 1-5s
  - Document processing: 10-120s (size dependent)
  - Embedding generation: 5-30s
  - Total: 16-155s per document

Query Processing:
  - Request receive: <100ms
  - Vector search: 100-500ms
  - Gemini generation: 1-3s
  - Total: 1.2-3.6s per query
```

---

This detailed architecture documentation provides a comprehensive view of the Super_RAG V1 system design.
