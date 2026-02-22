# Super_RAG V1 - Architecture Diagrams

## 1. High-Level System Architecture

```mermaid
graph TB
    subgraph "User Layer"
        U1[User - Document Upload]
        U2[User - Query]
    end

    subgraph "Storage Layer"
        GCS[("Cloud Storage Bucket<br/>rag-documents")]
        L[legal/]
        T[technical/]
        TR[training/]
    end

    subgraph "Event Layer"
        EA[Eventarc Trigger<br/>Object Finalize Event]
    end

    subgraph "Processing Layer - Ingestion"
        CR1[Cloud Run<br/>rag-ingestor<br/>FastAPI]
        CM[Corpus Mapper]
        VC[Vertex Client]
    end

    subgraph "AI/ML Layer"
        VAI[Vertex AI RAG Engine]
        EMB[Embedding Model<br/>text-embedding-004]
        VI[("Vector Index<br/>3 Corpora")]
        LC[Legal Corpus]
        TC[Technical Corpus]
        TRC[Training Corpus]
    end

    subgraph "Processing Layer - Query"
        CR2[Cloud Run<br/>adk-agent<br/>FastAPI]
        RR[RAG Retriever]
        AG[ADK Agent]
        GM[Gemini Model<br/>gemini-1.5-pro]
    end

    subgraph "Response"
        R[Grounded Response<br/>with Citations]
    end

    U1 -->|Upload PDF/DOC| GCS
    GCS --> L
    GCS --> T
    GCS --> TR

    L -->|Finalize Event| EA
    T -->|Finalize Event| EA
    TR -->|Finalize Event| EA

    EA -->|Trigger| CR1
    CR1 --> CM
    CM -->|Map to Corpus| VC
    VC -->|Import Document| VAI

    VAI --> EMB
    EMB -->|Generate Embeddings| VI
    VI --> LC
    VI --> TC
    VI --> TRC

    U2 -->|POST /query| CR2
    CR2 --> RR
    RR -->|Retrieve Context| VI
    VI -->|Top-K Chunks| RR
    RR --> AG
    AG -->|Generate with Context| GM
    GM --> R
    R -->|JSON Response| U2

    style U1 fill:#e1f5ff
    style U2 fill:#e1f5ff
    style GCS fill:#fff4e6
    style CR1 fill:#e8f5e9
    style CR2 fill:#e8f5e9
    style VAI fill:#f3e5f5
    style GM fill:#f3e5f5
    style VI fill:#fff3e0
    style R fill:#e1f5ff
```

## 2. Detailed Component Architecture

```mermaid
graph TB
    subgraph "Infrastructure Layer - Terraform Managed"
        subgraph "Network & IAM"
            SA1[Service Account<br/>rag-ingestor]
            SA2[Service Account<br/>adk-agent]
            SA3[Service Account<br/>eventarc-trigger]
        end

        subgraph "Storage"
            B1[("GCS Bucket<br/>Versioning ON<br/>Lifecycle: 90d")]
            AR[("Artifact Registry<br/>Docker Images")]
        end

        subgraph "Compute"
            CRI[Cloud Run - rag-ingestor<br/>CPU: 2, Mem: 4Gi<br/>Min: 0, Max: 10<br/>Timeout: 3600s]
            CRA[Cloud Run - adk-agent<br/>CPU: 2, Mem: 2Gi<br/>Min: 1, Max: 5<br/>Timeout: 300s]
        end

        subgraph "Monitoring"
            CL[Cloud Logging]
            CM[Cloud Monitoring]
            CT[Cloud Trace]
        end
    end

    subgraph "Application Layer"
        subgraph "rag-ingestor Service"
            API1[FastAPI App<br/>Port: 8080]
            CFG1[Config Manager<br/>Pydantic Settings]
            MAP[Corpus Mapper<br/>Folder → Corpus]
            VCL[Vertex Client<br/>RAG API Wrapper]
        end

        subgraph "adk-agent Service"
            API2[FastAPI App<br/>Port: 8080]
            CFG2[Config Manager<br/>Pydantic Settings]
            RET[RAG Retriever<br/>Query → Contexts]
            AGT[ADK Agent<br/>Context → Response]
        end
    end

    subgraph "Data Flow"
        DF1[1. Upload → GCS]
        DF2[2. Eventarc → Cloud Run]
        DF3[3. Process → Vertex AI]
        DF4[4. Embed → Vector Index]
        DF5[5. Query → Retrieve]
        DF6[6. Generate → Response]
    end

    SA1 --> CRI
    SA2 --> CRA
    SA3 --> CRI

    AR --> CRI
    AR --> CRA

    CRI --> API1
    API1 --> CFG1
    API1 --> MAP
    API1 --> VCL

    CRA --> API2
    API2 --> CFG2
    API2 --> RET
    API2 --> AGT

    CRI --> CL
    CRA --> CL
    CRI --> CM
    CRA --> CM
    CRI --> CT
    CRA --> CT

    style SA1 fill:#ffebee
    style SA2 fill:#ffebee
    style SA3 fill:#ffebee
    style CRI fill:#e8f5e9
    style CRA fill:#e8f5e9
    style B1 fill:#fff4e6
    style AR fill:#fff4e6
```

## 3. Data Flow Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant GCS as Cloud Storage
    participant Eventarc
    participant Ingestor as rag-ingestor
    participant VertexRAG as Vertex AI RAG
    participant VectorDB as Vector Index
    participant Agent as adk-agent
    participant Gemini

    Note over User,VectorDB: Document Ingestion Flow
    User->>GCS: Upload document.pdf to legal/
    GCS->>Eventarc: Object Finalize Event
    Eventarc->>Ingestor: POST / (CloudEvent)
    Ingestor->>Ingestor: Parse event data
    Ingestor->>Ingestor: Map folder → corpus (legal)
    Ingestor->>VertexRAG: import_files(corpus, gs://...)
    VertexRAG->>VertexRAG: Parse document
    VertexRAG->>VertexRAG: Chunk text (1000 tokens)
    VertexRAG->>VertexRAG: Generate embeddings
    VertexRAG->>VectorDB: Store vectors + metadata
    VectorDB-->>VertexRAG: Success
    VertexRAG-->>Ingestor: Import complete
    Ingestor-->>Eventarc: 200 OK

    Note over User,Gemini: Query Flow
    User->>Agent: POST /query {"query": "..."}
    Agent->>Agent: Parse request
    Agent->>VectorDB: retrieval_query(text, top_k=5)
    VectorDB->>VectorDB: Vector similarity search
    VectorDB-->>Agent: Top-K contexts with sources
    Agent->>Agent: Format contexts for prompt
    Agent->>Gemini: generate_content(prompt + contexts)
    Gemini->>Gemini: Generate response
    Gemini-->>Agent: Response text
    Agent->>Agent: Format response + citations
    Agent-->>User: {"response": "...", "contexts": [...]}
```

## 4. Infrastructure Topology

```mermaid
graph LR
    subgraph "GCP Project"
        subgraph "Region: us-central1"
            subgraph "Cloud Run Services"
                R1[rag-ingestor<br/>Internal]
                R2[adk-agent<br/>Authenticated]
            end

            subgraph "Storage"
                S1[GCS Bucket<br/>Regional]
                S2[Artifact Registry<br/>Regional]
            end

            subgraph "Vertex AI"
                V1[Legal Corpus]
                V2[Technical Corpus]
                V3[Training Corpus]
                V4[Vector Index]
            end

            subgraph "Eventarc"
                E1[GCS Trigger]
            end
        end

        subgraph "Global Services"
            IAM[IAM]
            SM[Secret Manager]
            LOG[Cloud Logging]
            MON[Cloud Monitoring]
        end
    end

    subgraph "External"
        CB[Cloud Build<br/>CI/CD]
        TF[Terraform State<br/>GCS Backend]
    end

    S1 --> E1
    E1 --> R1
    R1 --> V1
    R1 --> V2
    R1 --> V3
    V1 --> V4
    V2 --> V4
    V3 --> V4
    R2 --> V4

    IAM --> R1
    IAM --> R2
    SM -.->|Secrets| R1
    SM -.->|Secrets| R2
    LOG --> R1
    LOG --> R2
    MON --> R1
    MON --> R2

    CB -->|Deploy| R1
    CB -->|Deploy| R2
    CB -->|Build Images| S2
    S2 --> R1
    S2 --> R2

    TF -.->|Manage| S1
    TF -.->|Manage| R1
    TF -.->|Manage| R2

    style R1 fill:#4caf50
    style R2 fill:#4caf50
    style S1 fill:#ff9800
    style S2 fill:#ff9800
    style V1 fill:#9c27b0
    style V2 fill:#9c27b0
    style V3 fill:#9c27b0
    style V4 fill:#673ab7
    style E1 fill:#2196f3
```

## 5. Security & IAM Architecture

```mermaid
graph TB
    subgraph "Service Accounts"
        SA1[rag-ingestor@<br/>project.iam.gserviceaccount.com]
        SA2[adk-agent@<br/>project.iam.gserviceaccount.com]
        SA3[eventarc-trigger@<br/>project.iam.gserviceaccount.com]
        SA4[cloudbuild@<br/>project.iam.gserviceaccount.com]
    end

    subgraph "IAM Roles"
        R1[roles/aiplatform.user]
        R2[roles/storage.objectViewer]
        R3[roles/logging.logWriter]
        R4[roles/eventarc.eventReceiver]
        R5[roles/run.invoker]
        R6[roles/run.admin]
    end

    subgraph "Resources"
        GCS[(Cloud Storage)]
        VAI[Vertex AI]
        CRI[rag-ingestor<br/>Cloud Run]
        CRA[adk-agent<br/>Cloud Run]
        LOG[Cloud Logging]
    end

    SA1 --> R1
    SA1 --> R2
    SA1 --> R3

    SA2 --> R1
    SA2 --> R3

    SA3 --> R4
    SA3 --> R5

    SA4 --> R6
    SA4 --> R5

    R1 --> VAI
    R2 --> GCS
    R3 --> LOG
    R5 --> CRI
    R5 --> CRA
    R6 --> CRI
    R6 --> CRA

    style SA1 fill:#ffcdd2
    style SA2 fill:#ffcdd2
    style SA3 fill:#ffcdd2
    style SA4 fill:#ffcdd2
    style R1 fill:#c8e6c9
    style R2 fill:#c8e6c9
    style R3 fill:#c8e6c9
    style R4 fill:#c8e6c9
    style R5 fill:#c8e6c9
    style R6 fill:#c8e6c9
```

## 6. CI/CD Pipeline Flow

```mermaid
graph LR
    subgraph "Source Control"
        GIT[Git Push to main]
    end

    subgraph "Cloud Build Triggers"
        T1[Trigger: rag-ingestor]
        T2[Trigger: adk-agent]
        T3[Trigger: terraform]
    end

    subgraph "Build Stages - Services"
        B1[1. Run Tests]
        B2[2. Build Docker]
        B3[3. Push to AR]
        B4[4. Deploy to CR]
        B5[5. Verify Health]
    end

    subgraph "Build Stages - Infrastructure"
        I1[1. Terraform fmt]
        I2[2. Terraform init]
        I3[3. Terraform validate]
        I4[4. Terraform plan]
        I5[5. Terraform apply]
    end

    subgraph "Deployment"
        D1[Cloud Run<br/>rag-ingestor]
        D2[Cloud Run<br/>adk-agent]
        D3[GCP Infrastructure]
    end

    GIT --> T1
    GIT --> T2
    GIT --> T3

    T1 --> B1
    T2 --> B1
    B1 --> B2
    B2 --> B3
    B3 --> B4
    B4 --> B5

    T3 --> I1
    I1 --> I2
    I2 --> I3
    I3 --> I4
    I4 --> I5

    B5 --> D1
    B5 --> D2
    I5 --> D3

    style GIT fill:#64b5f6
    style T1 fill:#81c784
    style T2 fill:#81c784
    style T3 fill:#81c784
    style D1 fill:#4caf50
    style D2 fill:#4caf50
    style D3 fill:#4caf50
```

## 7. Cost Breakdown Architecture

```mermaid
graph TB
    subgraph "Monthly Cost Structure"
        subgraph "Compute - $50-100"
            C1[Cloud Run rag-ingestor<br/>Pay per use<br/>Min: 0 instances]
            C2[Cloud Run adk-agent<br/>Pay per use<br/>Min: 1 instance]
        end

        subgraph "Storage - $5-20"
            S1[Cloud Storage<br/>Standard: 90 days<br/>Nearline: After 90d]
            S2[Artifact Registry<br/>Docker Images]
        end

        subgraph "AI/ML - $100-300"
            A1[Vertex AI Embeddings<br/>Pay per API call]
            A2[Vertex AI RAG Retrieval<br/>Pay per query]
            A3[Gemini API<br/>Pay per token]
        end

        subgraph "Operations - $10-50"
            O1[Cloud Logging]
            O2[Cloud Monitoring]
            O3[Cloud Trace]
        end

        subgraph "Free Tier"
            F1[Eventarc<br/>Included]
            F2[Cloud Build<br/>120 min/day free]
        end
    end

    TOTAL[Total: $165-470/month<br/>Varies by usage]

    C1 --> TOTAL
    C2 --> TOTAL
    S1 --> TOTAL
    S2 --> TOTAL
    A1 --> TOTAL
    A2 --> TOTAL
    A3 --> TOTAL
    O1 --> TOTAL
    O2 --> TOTAL
    O3 --> TOTAL

    style C1 fill:#fff9c4
    style C2 fill:#fff9c4
    style S1 fill:#fff9c4
    style S2 fill:#fff9c4
    style A1 fill:#ffccbc
    style A2 fill:#ffccbc
    style A3 fill:#ffccbc
    style O1 fill:#e1f5fe
    style O2 fill:#e1f5fe
    style O3 fill:#e1f5fe
    style F1 fill:#c8e6c9
    style F2 fill:#c8e6c9
    style TOTAL fill:#ef5350,color:#fff
```

## 8. Terraform Module Dependencies

```mermaid
graph TD
    subgraph "Terraform Modules"
        ROOT[Root Module<br/>main.tf]

        MOD1[storage module<br/>GCS Bucket]
        MOD2[iam module<br/>Service Accounts]
        MOD3[vertex-ai module<br/>RAG Corpora]
        MOD4[cloud-run module<br/>Services]
        MOD5[eventarc module<br/>Triggers]
    end

    subgraph "Resources Created"
        R1[GCS Bucket<br/>+ Folders]
        R2[3 Service Accounts<br/>+ IAM Bindings]
        R3[3 RAG Corpus Names<br/>Config Only]
        R4[2 Cloud Run Services<br/>+ IAM Policies]
        R5[1 Eventarc Trigger<br/>+ Pub/Sub IAM]
    end

    ROOT --> MOD1
    ROOT --> MOD2
    ROOT --> MOD3
    ROOT --> MOD4
    ROOT --> MOD5

    MOD1 --> R1
    MOD2 --> R2
    MOD3 --> R3
    MOD4 --> R4
    MOD5 --> R5

    MOD3 -.->|depends_on| MOD1
    MOD4 -.->|depends_on| MOD2
    MOD4 -.->|depends_on| MOD3
    MOD5 -.->|depends_on| MOD4
    MOD5 -.->|depends_on| MOD1

    style ROOT fill:#1976d2,color:#fff
    style MOD1 fill:#4caf50
    style MOD2 fill:#4caf50
    style MOD3 fill:#4caf50
    style MOD4 fill:#4caf50
    style MOD5 fill:#4caf50
```

## Architecture Key Points

### Scalability
- **Cloud Run**: Auto-scales from 0 to 10 instances for ingestor
- **Vertex AI**: Managed vector index handles large-scale retrieval
- **Eventarc**: Handles high-volume file uploads asynchronously

### Reliability
- **Retry Logic**: Tenacity library with exponential backoff
- **Health Checks**: Liveness and startup probes on Cloud Run
- **State Management**: Terraform remote state with locking

### Security
- **Least Privilege**: Each service has minimal IAM permissions
- **Authentication**: IAM-based auth for all Cloud Run services
- **Secrets**: Secret Manager for sensitive configuration
- **Network**: Uniform bucket-level access, internal-only ingress

### Observability
- **Logging**: Structured JSON logs to Cloud Logging
- **Monitoring**: Metrics exported to Cloud Monitoring
- **Tracing**: Cloud Trace for request tracking
- **Alerting**: Budget alerts and error rate monitoring

### Cost Optimization
- **Scale to Zero**: rag-ingestor min instances = 0
- **Lifecycle Policies**: Move old data to Nearline storage
- **Batch Processing**: Chunk documents efficiently
- **Budget Alerts**: Set at $500/month with 50%, 80%, 100% notifications
