#!/bin/bash
set -e

# Check if environment parameter is provided
if [ $# -eq 0 ]; then
    echo "❌ Error: Environment parameter is required"
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    echo "Available environments: dev, test, prod"
    exit 1
fi

ENVIRONMENT=$1
PROJECT_ID=${2:-cyber-analyzer-490508}

echo "🗑️ Preparing to destroy ${PROJECT_ID}-${ENVIRONMENT} infrastructure..."

# Navigate to terraform directory
cd terraform
cd gcp

# Get GCP Region for backend configuration
GCP_REGION=${DEFAULT_GCP_REGION:-europe-southwest1}

# Initialize terraform
echo "🔧 Initializing Terraform..."
terraform init -input=false \
  -backend-config="bucket=cyber-analyzer-tfstate" \
  -backend-config="prefix=${ENVIRONMENT}"

# Check if workspace exists
if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
    echo "❌ Error: Workspace '$ENVIRONMENT' does not exist"
    echo "Available workspaces:"
    terraform workspace list
    exit 1
fi

# Select the workspace
terraform workspace select "$ENVIRONMENT"

echo "🔥 Running terraform destroy..."

# Run terraform destroy with auto-approve
if [ "$ENVIRONMENT" = "prod" ] && [ -f "prod.tfvars" ]; then
    terraform destroy -var-file=prod.tfvars -var="project_id=$PROJECT_ID" -var="environment=$ENVIRONMENT" -auto-approve
else
    terraform destroy -var="project_id=$PROJECT_ID" -var="environment=$ENVIRONMENT" -auto-approve
fi

echo "✅ Infrastructure for ${ENVIRONMENT} has been destroyed!"
echo ""
echo "💡 To remove the workspace completely, run:"
echo "   terraform workspace select default"
echo "   terraform workspace delete $ENVIRONMENT"