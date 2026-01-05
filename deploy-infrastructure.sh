#!/bin/bash

################################################################################
# Azure Infrastructure Deployment Script
#
# This script automates the complete deployment of:
# - Base layer (VNet, Subnets, Key Vault, Application Gateway resources)
# - SSL Certificate generation and upload
# - Sample API Docker image build and push to ACR
# - Backend layer (Container Registry, Container App, Application Gateway)
#
# Prerequisites:
# - Azure CLI installed and logged in
# - Terraform installed (v1.0+)
# - Docker installed (for building sample API)
# - OpenSSL installed (for certificate generation)
# - Proper Azure subscription access
#
# Usage:
#   chmod +x deploy-infrastructure.sh
#   ./deploy-infrastructure.sh
#
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="deployment-$(date +%Y%m%d-%H%M%S).log"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

print_section() {
    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo -e "${GREEN}$1${NC}" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
}

# Function to check command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"

    local all_ok=true

    # Check Azure CLI
    if command_exists az; then
        AZ_VERSION=$(az version --query '"azure-cli"' -o tsv)
        print_success "Azure CLI installed: $AZ_VERSION"
    else
        print_error "Azure CLI not found. Please install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        all_ok=false
    fi

    # Check Terraform
    if command_exists terraform; then
        TF_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
        print_success "Terraform installed: $TF_VERSION"
    else
        print_error "Terraform not found. Please install from: https://www.terraform.io/downloads"
        all_ok=false
    fi

    # Check Docker
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
        print_success "Docker installed: $DOCKER_VERSION"
    else
        print_warning "Docker not found. Sample API deployment will be skipped."
    fi

    # Check OpenSSL
    if command_exists openssl; then
        OPENSSL_VERSION=$(openssl version | cut -d' ' -f2)
        print_success "OpenSSL installed: $OPENSSL_VERSION"
    else
        print_warning "OpenSSL not found. SSL certificate generation will be skipped."
    fi

    # Check Azure login
    if az account show &>/dev/null; then
        ACCOUNT=$(az account show --query name -o tsv)
        SUBSCRIPTION_ID=$(az account show --query id -o tsv)
        print_success "Logged into Azure subscription: $ACCOUNT ($SUBSCRIPTION_ID)"
    else
        print_error "Not logged into Azure. Run: az login"
        all_ok=false
    fi

    if [ "$all_ok" = false ]; then
        print_error "Prerequisites check failed. Please fix the issues above."
        exit 1
    fi

    print_success "All prerequisites satisfied!"
}

# Function to initialize and deploy Terraform
deploy_terraform() {
    local layer_path=$1
    local layer_name=$2

    print_section "Deploying $layer_name"

    cd "$layer_path"
    print_info "Working directory: $(pwd)"

    # Initialize Terraform
    print_info "Initializing Terraform..."
    if terraform init -upgrade 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Terraform initialized"
    else
        print_error "Terraform init failed for $layer_name"
        exit 1
    fi

    # Plan
    print_info "Creating Terraform plan..."
    if terraform plan -out=tfplan 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Terraform plan created"
    else
        print_error "Terraform plan failed for $layer_name"
        exit 1
    fi

    # Apply
    print_info "Applying Terraform changes..."
    if terraform apply -auto-approve tfplan 2>&1 | tee -a "$LOG_FILE"; then
        print_success "$layer_name deployed successfully!"
    else
        print_error "Terraform apply failed for $layer_name"
        exit 1
    fi

    # Clean up plan file
    rm -f tfplan

    cd - > /dev/null
}

# Function to generate and upload SSL certificate
setup_ssl_certificate() {
    print_section "Setting Up SSL Certificate"

    if ! command_exists openssl; then
        print_warning "OpenSSL not found. Skipping SSL certificate generation."
        return
    fi

    # Get Key Vault name
    print_info "Retrieving Key Vault name..."
    cd azure-terrafrom/layers/100_base/env/prod
    KEY_VAULT_NAME=$(terraform output -raw key_vault_name 2>/dev/null)
    cd - > /dev/null

    if [ -z "$KEY_VAULT_NAME" ]; then
        print_error "Could not retrieve Key Vault name. Make sure base layer is deployed."
        exit 1
    fi

    print_info "Key Vault: $KEY_VAULT_NAME"

    # Check if certificate already exists
    if az keyvault certificate show --vault-name "$KEY_VAULT_NAME" --name ssl-certificate &>/dev/null; then
        print_warning "SSL certificate already exists in Key Vault. Skipping generation."
        return
    fi

    # Generate self-signed certificate
    print_info "Generating self-signed SSL certificate..."
    CERT_DIR="./temp-certs"
    mkdir -p "$CERT_DIR"

    openssl req -x509 -newkey rsa:4096 -sha256 -days 365 \
        -nodes -keyout "$CERT_DIR/ssl-certificate.key" \
        -out "$CERT_DIR/ssl-certificate.crt" \
        -subj "/CN=ztf-appgateway.example.com/O=ZTF/C=US" \
        -extensions san \
        -config <(echo "[req]";
                  echo "distinguished_name=req";
                  echo "[san]";
                  echo "subjectAltName=DNS:ztf-appgateway.example.com,DNS:*.ztf-appgateway.example.com") \
        2>&1 | tee -a "$LOG_FILE"

    # Convert to PFX format
    print_info "Converting certificate to PFX format..."
    openssl pkcs12 -export \
        -out "$CERT_DIR/ssl-certificate.pfx" \
        -inkey "$CERT_DIR/ssl-certificate.key" \
        -in "$CERT_DIR/ssl-certificate.crt" \
        -password pass: \
        2>&1 | tee -a "$LOG_FILE"

    # Upload to Key Vault
    print_info "Uploading certificate to Key Vault..."
    if az keyvault certificate import \
        --vault-name "$KEY_VAULT_NAME" \
        --name ssl-certificate \
        --file "$CERT_DIR/ssl-certificate.pfx" \
        --password "" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "SSL certificate uploaded to Key Vault"
    else
        print_error "Failed to upload certificate to Key Vault"
        exit 1
    fi

    # Clean up temporary files
    rm -rf "$CERT_DIR"
    print_info "Cleaned up temporary certificate files"
}

# Function to build and push sample API
deploy_sample_api() {
    print_section "Building and Deploying Sample API"

    if ! command_exists docker; then
        print_warning "Docker not found. Skipping sample API deployment."
        return
    fi

    # Get ACR details
    print_info "Retrieving ACR details..."
    cd azure-terrafrom/layers/400_backend/env/prod

    ACR_NAME=$(terraform output -raw acr_login_server 2>/dev/null | cut -d'.' -f1)

    if [ -z "$ACR_NAME" ]; then
        print_error "Could not retrieve ACR name. Make sure backend layer is deployed."
        exit 1
    fi

    print_info "ACR Name: $ACR_NAME"
    cd - > /dev/null

    # Login to ACR
    print_info "Logging into ACR..."
    if az acr login --name "$ACR_NAME" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Logged into ACR"
    else
        print_error "Failed to login to ACR"
        exit 1
    fi

    # Build and push using ACR Build (no local Docker daemon needed)
    print_info "Building and pushing sample-api image to ACR..."
    cd azure-terrafrom/layers/400_backend/sample-api

    if az acr build --registry "$ACR_NAME" --image sample-api:latest . 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Sample API image built and pushed successfully!"
    else
        print_error "Failed to build/push sample API image"
        exit 1
    fi

    cd - > /dev/null

    # Restart Container App to use new image
    print_info "Restarting Container App to use new image..."
    CONTAINER_APP_NAME=$(cd azure-terrafrom/layers/400_backend/env/prod && terraform output -raw container_app_name 2>/dev/null)
    RG_NAME="ZTF-PROD-BACKEND"

    if az containerapp revision restart \
        --name "$CONTAINER_APP_NAME" \
        --resource-group "$RG_NAME" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Container App restarted"
    else
        print_warning "Could not restart Container App automatically. It will restart on its own."
    fi
}

# Function to verify deployment
verify_deployment() {
    print_section "Verifying Deployment"

    # Get Application Gateway public IP
    print_info "Retrieving Application Gateway public IP..."
    cd azure-terrafrom/layers/400_backend/env/prod
    APP_GW_IP=$(terraform output -raw application_gateway_public_ip 2>/dev/null)
    cd - > /dev/null

    if [ -z "$APP_GW_IP" ]; then
        print_warning "Could not retrieve Application Gateway IP. Skipping verification."
        return
    fi

    print_info "Application Gateway IP: $APP_GW_IP"

    # Wait for Application Gateway to be ready
    print_info "Waiting 60 seconds for Application Gateway to stabilize..."
    sleep 60

    # Test endpoints
    print_info "Testing API endpoints..."

    # Test root endpoint
    print_info "Testing root endpoint (/)..."
    if curl -kL --max-time 30 "https://$APP_GW_IP/" 2>&1 | tee -a "$LOG_FILE" | grep -q "Welcome"; then
        print_success "Root endpoint responding"
    else
        print_warning "Root endpoint not responding yet (may need more time to initialize)"
    fi

    # Test health endpoint
    print_info "Testing health endpoint (/api/health)..."
    if curl -kL --max-time 30 "https://$APP_GW_IP/api/health" 2>&1 | tee -a "$LOG_FILE" | grep -q "healthy"; then
        print_success "Health endpoint responding"
    else
        print_warning "Health endpoint not responding yet (may need more time to initialize)"
    fi

    # Check backend health
    print_info "Checking Application Gateway backend health..."
    APP_GW_NAME="ZTF-apg-appgateway-prod-eus-001"
    RG_NAME="ZTF-PROD-BACKEND"

    HEALTH_STATUS=$(az network application-gateway show-backend-health \
        --name "$APP_GW_NAME" \
        --resource-group "$RG_NAME" \
        --query "backendAddressPools[0].backendHttpSettingsCollection[0].servers[0].health" \
        -o tsv 2>/dev/null)

    if [ "$HEALTH_STATUS" = "Healthy" ]; then
        print_success "Backend health status: Healthy"
    else
        print_warning "Backend health status: $HEALTH_STATUS (may need more time to stabilize)"
    fi
}

# Function to display deployment summary
display_summary() {
    print_section "Deployment Summary"

    # Get outputs
    cd azure-terrafrom/layers/400_backend/env/prod
    APP_GW_IP=$(terraform output -raw application_gateway_public_ip 2>/dev/null)
    CONTAINER_APP_FQDN=$(terraform output -raw container_app_fqdn 2>/dev/null)
    ACR_SERVER=$(terraform output -raw acr_login_server 2>/dev/null)
    cd - > /dev/null

    echo "" | tee -a "$LOG_FILE"
    echo "╔════════════════════════════════════════════════════════╗" | tee -a "$LOG_FILE"
    echo "║          DEPLOYMENT COMPLETED SUCCESSFULLY!           ║" | tee -a "$LOG_FILE"
    echo "╚════════════════════════════════════════════════════════╝" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "📊 Infrastructure Details:" | tee -a "$LOG_FILE"
    echo "  • Application Gateway IP: $APP_GW_IP" | tee -a "$LOG_FILE"
    echo "  • Container App FQDN: $CONTAINER_APP_FQDN" | tee -a "$LOG_FILE"
    echo "  • ACR Server: $ACR_SERVER" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "🧪 Test Commands:" | tee -a "$LOG_FILE"
    echo "  curl -kL https://$APP_GW_IP/" | tee -a "$LOG_FILE"
    echo "  curl -kL https://$APP_GW_IP/api/health" | tee -a "$LOG_FILE"
    echo "  curl -kL https://$APP_GW_IP/api/test" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "📚 Documentation:" | tee -a "$LOG_FILE"
    echo "  • DEPLOYMENT_GUIDE.md" | tee -a "$LOG_FILE"
    echo "  • AZURE_PORTAL_GUIDE.md" | tee -a "$LOG_FILE"
    echo "  • FINAL_DEPLOYMENT_SUMMARY.md" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "📝 Deployment log saved to: $LOG_FILE" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Function to handle errors
cleanup_on_error() {
    print_error "Deployment failed! Check $LOG_FILE for details."
    exit 1
}

# Trap errors
trap cleanup_on_error ERR

################################################################################
# MAIN DEPLOYMENT FLOW
################################################################################

main() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║     Azure Infrastructure Deployment Script            ║"
    echo "║     Application Gateway + Container Apps              ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""

    START_TIME=$(date +%s)

    # Step 1: Check prerequisites
    check_prerequisites

    # Step 2: Deploy base layer
    deploy_terraform "azure-terrafrom/layers/100_base/env/prod" "Base Layer (100_base)"

    # Step 3: Setup SSL certificate
    setup_ssl_certificate

    # Step 4: Deploy backend layer
    deploy_terraform "azure-terrafrom/layers/400_backend/env/prod" "Backend Layer (400_backend)"

    # Step 5: Build and deploy sample API
    deploy_sample_api

    # Step 6: Verify deployment
    verify_deployment

    # Calculate deployment time
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))

    print_success "Total deployment time: ${MINUTES}m ${SECONDS}s"

    # Step 7: Display summary
    display_summary
}

# Run main function
main
