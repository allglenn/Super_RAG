#!/bin/bash

# Super_RAG V1 - Terraform Backend Setup Script
# This script creates a GCS bucket for Terraform state management

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

BUCKET_NAME="${GCP_PROJECT_ID}-terraform-state"

echo -e "${GREEN}Creating Terraform state bucket: $BUCKET_NAME${NC}"

# Create the bucket
gsutil mb -p $GCP_PROJECT_ID -c STANDARD -l $GCP_REGION gs://$BUCKET_NAME/ || \
    echo -e "${YELLOW}Bucket might already exist${NC}"

# Enable versioning
echo "Enabling versioning..."
gsutil versioning set on gs://$BUCKET_NAME/

# Set uniform bucket-level access
echo "Setting uniform bucket-level access..."
gsutil uniformbucketlevelaccess set on gs://$BUCKET_NAME/

# Set lifecycle rule to delete old versions after 30 days
echo "Setting lifecycle policy..."
cat > /tmp/lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "numNewerVersions": 3,
          "isLive": false
        }
      }
    ]
  }
}
EOF

gsutil lifecycle set /tmp/lifecycle.json gs://$BUCKET_NAME/
rm /tmp/lifecycle.json

echo -e "\n${GREEN}Terraform backend bucket created successfully!${NC}"
echo -e "${YELLOW}Bucket name: ${NC}$BUCKET_NAME"
echo -e "${YELLOW}Location: ${NC}$GCP_REGION"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update terraform/backend.tf with bucket name: $BUCKET_NAME"
echo "2. Run 'cd terraform && terraform init' to initialize Terraform"
