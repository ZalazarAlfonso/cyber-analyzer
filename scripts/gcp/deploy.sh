#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}          # dev | test | prod
PROJECT_NAME=${2:-cyber-analyzer}
export $(cat .env | xargs)
GCP_ACCOUNT_ID=$(gcloud auth list --format="value(account)")
GCP_REGION=${DEFAULT_GCP_REGION:-eu-southwest1}
PROJECT_ID=${GCP_PROJECT_ID}

echo "🚀 Deploying ${PROJECT_NAME} to ${ENVIRONMENT}..."
echo "Project ID: ${PROJECT_ID}"

# 1. Terraform workspace & apply
cd terraform
cd gcp


terraform init -input=false \
  -backend-config="bucket=cyber-analyzer-tfstate" \
  -backend-config="prefix=${ENVIRONMENT}"

if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
  terraform workspace new "$ENVIRONMENT"
else
  terraform workspace select "$ENVIRONMENT"
fi

# Use prod.tfvars for production environment
if [ "$ENVIRONMENT" = "prod" ]; then
  TF_APPLY_CMD=(terraform apply -var-file=prod.tfvars -var="project_name=$PROJECT_NAME" -var="project_id=$PROJECT_ID" -var="environment=$ENVIRONMENT" -auto-approve)
else
  TF_APPLY_CMD=(terraform apply -var="project_name=$PROJECT_NAME" -var="project_id=$PROJECT_ID" -var="environment=$ENVIRONMENT" -auto-approve)
fi

echo "🎯 Applying Terraform..."
"${TF_APPLY_CMD[@]}"

CUSTOM_URL=$(terraform output -raw service_url 2>/dev/null || true)

# 2. Final messages
echo -e "\n✅ Deployment complete!"
echo "🌐 Service URL : $(terraform -chdir=terraform output -raw service_url)"