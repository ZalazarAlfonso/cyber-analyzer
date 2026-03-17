#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}          # dev | test | prod
PROJECT_NAME=${2:-cyber-analyzer}

echo "🚀 Deploying ${PROJECT_NAME} to ${ENVIRONMENT}..."

# 1. Terraform workspace & apply
cd terraform
cd gcp
GCP_ACCOUNT_ID=$(gcloud auth list --format="value(account)")
GCP_REGION=${DEFAULT_GCP_REGION:-eu-southwest1}
OPENAI_API_KEY=${OPENAI_API_KEY}
SEMGREP_APP_TOKEN=${SEMGREP_APP_TOKEN}

terraform init -input=false \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${GCP_REGION}"

if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
  terraform workspace new "$ENVIRONMENT"
else
  terraform workspace select "$ENVIRONMENT"
fi

# Use prod.tfvars for production environment
if [ "$ENVIRONMENT" = "prod" ]; then
  TF_APPLY_CMD=(terraform apply -var="openai_api_key=$OPENAI_API_KEY" -var="semgrep_app_token=$SEMGREP_APP_TOKEN" -var-file=prod.tfvars -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve)
else
  TF_APPLY_CMD=(terraform apply -var="openai_api_key=$OPENAI_API_KEY" -var="semgrep_app_token=$SEMGREP_APP_TOKEN" -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve)
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