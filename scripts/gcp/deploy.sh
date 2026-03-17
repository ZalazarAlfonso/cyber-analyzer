#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}          # dev | test | prod
PROJECT_NAME=${2:-cyber-analyzer}
export $(cat .env | xargs)

echo "🚀 Deploying ${PROJECT_NAME} to ${ENVIRONMENT}..."
echo "Project ID: $TF_VAR_project_id"
echo "OpenAI key loaded: ${OPENAI_API_KEY:0:8}..."
echo "Semgrep token loaded: ${SEMGREP_APP_TOKEN:0:8}..."

# 1. Terraform workspace & apply
cd terraform
cd gcp
GCP_ACCOUNT_ID=$(gcloud auth list --format="value(account)")
GCP_REGION=${DEFAULT_GCP_REGION:-eu-southwest1}
PROJECT_ID=${GCP_PROJECT_ID}

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
  TF_APPLY_CMD=(terraform apply -var="openai_api_key=$OPENAI_API_KEY" -var="semgrep_app_token=$SEMGREP_APP_TOKEN" -var-file=prod.tfvars -var="project_id=$PROJECT_ID" -var="environment=$ENVIRONMENT" -auto-approve)
else
  TF_APPLY_CMD=(terraform apply -var="openai_api_key=$OPENAI_API_KEY" -var="semgrep_app_token=$SEMGREP_APP_TOKEN" -var="project_id=$PROJECT_ID" -var="environment=$ENVIRONMENT" -auto-approve)
fi

echo "🎯 Applying Terraform..."
"${TF_APPLY_CMD[@]}"

CUSTOM_URL=$(terraform output -raw service_url 2>/dev/null || true)

# 2. Final messages
echo -e "\n✅ Deployment complete!"
echo "🌐 Service URL : $(terraform -chdir=terraform output -raw service_url)"
if [ -n "$CUSTOM_URL" ]; then
  echo "🔗 Custom domain  : $CUSTOM_URL"
fi