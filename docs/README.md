# Super_RAG V1 - Documentation

This directory contains detailed architecture documentation for the Super_RAG V1 system.

## Available Documentation

### 1. [Architecture Diagrams](architecture-diagram.md)
Comprehensive visual diagrams using Mermaid syntax including:
- **High-Level System Architecture**: Complete data flow from upload to query response
- **Detailed Component Architecture**: Service internals and dependencies
- **Data Flow Sequence Diagram**: Step-by-step processing sequence
- **Infrastructure Topology**: GCP resource organization
- **Security & IAM Architecture**: Service accounts and permissions
- **CI/CD Pipeline Flow**: Build and deployment stages
- **Cost Breakdown**: Monthly cost structure
- **Terraform Module Dependencies**: Infrastructure provisioning flow

### 2. [Detailed Architecture Guide](architecture-detailed.md)
In-depth technical documentation covering:
- **System Overview**: Layered architecture breakdown
- **Component Architecture**: Detailed pipeline descriptions
- **Network Architecture**: Service communication patterns
- **Data Architecture**: Document lifecycle and data models
- **Security Architecture**: Defense in depth strategy
- **Deployment Architecture**: Terraform and CI/CD workflows

## How to View Mermaid Diagrams

Mermaid diagrams can be viewed in several ways:

### Option 1: GitHub/GitLab
Simply view the `.md` files on GitHub or GitLab - they render Mermaid diagrams natively.

### Option 2: VS Code
Install the "Markdown Preview Mermaid Support" extension:
```bash
code --install-extension bierner.markdown-mermaid
```
Then open any `.md` file and click "Open Preview" (Ctrl+Shift+V or Cmd+Shift+V).

### Option 3: Online Editors
Copy the Mermaid code and paste it into:
- [Mermaid Live Editor](https://mermaid.live)
- [Mermaid Chart](https://www.mermaidchart.com/)

### Option 4: CLI Tool
```bash
npm install -g @mermaid-js/mermaid-cli
mmdc -i architecture-diagram.md -o architecture-diagram.pdf
```

## Architecture Quick Reference

### Key Components

| Component | Type | Purpose | Scale |
|-----------|------|---------|-------|
| rag-ingestor | Cloud Run | Document processing | 0-10 instances |
| adk-agent | Cloud Run | Query answering | 1-5 instances |
| GCS Bucket | Storage | Source documents | Unlimited |
| Vector Index | Vertex AI | Embeddings storage | Managed |
| Eventarc | Event | Upload trigger | Managed |

### Data Flow Summary

```
Upload → Storage → Eventarc → Ingestor → Vertex AI → Vector Index
                                                            ↓
Query → Agent → Retriever → Vector Index → Gemini → Response
```

### Security Model

- **Authentication**: IAM-based for all services
- **Authorization**: Dedicated service accounts with least privilege
- **Encryption**: At rest (Google-managed) and in transit (TLS)
- **Network**: Internal ingress for ingestor, authenticated for agent

### Cost Optimization

- **Scale to Zero**: Ingestor scales to 0 when idle
- **Lifecycle Policies**: Move to Nearline after 90 days
- **Min Instances**: Agent keeps 1 instance for low latency
- **Budget Alerts**: Set at $500/month

## Additional Resources

- **Main README**: [../README.md](../README.md) - Setup and usage guide
- **Terraform Code**: [../terraform/](../terraform/) - Infrastructure as Code
- **Service Code**: [../services/](../services/) - Application implementation
- **Build Configs**: [../cloudbuild/](../cloudbuild/) - CI/CD pipelines

## Architecture Versions

- **Current**: V1 (Document-based RAG)
- **Planned**: V2 (Multimodal RAG with video/image support)

## Feedback

For architecture questions or suggestions, please refer to the main project documentation or submit an issue.
