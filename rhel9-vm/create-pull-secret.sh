#!/bin/bash
# Script to create Red Hat registry pull secret for RHEL 9 VM

set -e

SECRET_NAME="redhat-registry-pull-secret"
NAMESPACE="rhel9-vms"

echo "=========================================="
echo "Red Hat Registry Pull Secret Creator"
echo "=========================================="
echo ""
echo "This script will create a pull secret for registry.redhat.io"
echo ""
echo "You'll need your Red Hat Customer Portal credentials."
echo "Get them from: https://access.redhat.com/RegistryAuthentication"
echo ""

# Check if oc is available
if ! command -v oc &> /dev/null; then
    echo "ERROR: OpenShift CLI (oc) is not installed or not in PATH"
    exit 1
fi

# Check if logged in
if ! oc whoami &> /dev/null; then
    echo "ERROR: Not logged in to OpenShift"
    echo "Please run: oc login <your-cluster-url>"
    exit 1
fi

echo "✓ Logged in as: $(oc whoami)"
echo ""

# Check if namespace exists
if ! oc get namespace "$NAMESPACE" &> /dev/null; then
    echo "Creating namespace: $NAMESPACE"
    oc create namespace "$NAMESPACE"
fi

# Prompt for credentials
read -p "Enter your Red Hat Customer Portal username: " REDHAT_USERNAME
read -sp "Enter your Red Hat Customer Portal password: " REDHAT_PASSWORD
echo ""

# Create the secret
echo ""
echo "Creating pull secret: $SECRET_NAME in namespace: $NAMESPACE"
oc create secret docker-registry "$SECRET_NAME" \
  --docker-server=registry.redhat.io \
  --docker-username="$REDHAT_USERNAME" \
  --docker-password="$REDHAT_PASSWORD" \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml | oc apply -f -

echo ""
echo "✅ Pull secret created successfully!"
echo ""
echo "Next steps:"
echo "1. Set the Terraform variable in Terraform Cloud:"
echo "   - Variable name: vm_registry_pull_secret"
echo "   - Variable value: $SECRET_NAME"
echo "   - Type: terraform"
echo ""
echo "2. Apply your Terraform configuration:"
echo "   cd rhel9-vm && terraform apply"

