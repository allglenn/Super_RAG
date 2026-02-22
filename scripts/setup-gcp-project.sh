#!/bin/bash

# Super_RAG V1 - GCP Project Setup Script
# This script enables required APIs and sets up initial project configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if PROJECT_ID is set
if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}Error: GCP_PROJECT_ID environment variable is not set${NC}"
    echo "Please set it using: export GCP_PROJECT_ID=your-project-id"
    exit 1
fi

# Check if REGION is set
if [ -z "$GCP_REGION" ]; then
    echo -e "${YELLOW}Warning: GCP_REGION not set, using default: us-central1${NC}"
    GCP_REGION="us-central1"
fi

echo -e "${GREEN}Starting GCP Project Setup for: $GCP_PROJECT_ID${NC}"
echo -e "${GREEN}Region: $GCP_REGION${NC}"
echo ""

# Set the active project
echo "Setting active project..."
gcloud config set project $GCP_PROJECT_ID

# Enable required APIs
echo -e "\n${GREEN}Enabling required APIs...${NC}"

APIS=(
    "storage.googleapis.com"
    "run.googleapis.com"
    "eventarc.googleapis.com"
    "aiplatform.googleapis.com"
    "cloudbuild.googleapis.com"
    "secretmanager.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "iam.googleapis.com"
    "artifactregistry.googleapis.com"
    "compute.googleapis.com"
)

for api in "${APIS[@]}"; do
    echo "Enabling $api..."
    gcloud services enable $api --project=$GCP_PROJECT_ID
done

echo -e "\n${GREEN}Creating Artifact Registry repository...${NC}"
gcloud artifacts repositories create rag-docker-repo \
    --repository-format=docker \
    --location=$GCP_REGION \
    --description="Docker repository for Super RAG services" \
    --project=$GCP_PROJECT_ID || echo "Repository might already exist"

echo -e "\n${GREEN}Granting necessary permissions to Cloud Build service account...${NC}"
PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT_ID --format="value(projectNumber)")
CLOUD_BUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member="serviceAccount:${CLOUD_BUILD_SA}" \
    --role="roles/run.admin" \
    --condition=None

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
    --member="serviceAccount:${CLOUD_BUILD_SA}" \
    --role="roles/iam.serviceAccountUser" \
    --condition=None

echo -e "\n${GREEN}GCP Project setup completed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run ./scripts/create-tf-backend.sh to create Terraform state bucket"
echo "2. Configure terraform/terraform.tfvars with your project settings"
echo "3. Run 'cd terraform && terraform init && terraform plan'"
