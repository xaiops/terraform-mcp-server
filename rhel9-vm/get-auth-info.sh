#!/bin/bash
# Helper script to get authentication information for Terraform Cloud

echo "=========================================="
echo "OpenShift Authentication Information"
echo "=========================================="
echo ""

# Check if oc is available
if ! command -v oc &> /dev/null; then
    echo "ERROR: OpenShift CLI (oc) is not installed or not in PATH"
    echo "Please install it first: https://docs.openshift.com/"
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

# Get Token
echo "1. KUBE_TOKEN (Environment Variable - Sensitive):"
echo "   Run: oc whoami -t"
TOKEN=$(oc whoami -t 2>/dev/null)
if [ -n "$TOKEN" ]; then
    echo "   Token: ${TOKEN:0:20}... (truncated for security)"
    echo "   Full token copied to clipboard (if available)"
    echo "$TOKEN" | pbcopy 2>/dev/null || echo "$TOKEN"
else
    echo "   Failed to get token"
fi
echo ""

# Get CA Certificate
echo "2. KUBE_CLUSTER_CA_CERT_DATA (Environment Variable):"
CA_CERT=$(oc config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' 2>/dev/null)
if [ -n "$CA_CERT" ]; then
    echo "   CA Certificate: ${CA_CERT:0:40}... (truncated)"
    echo "   Full certificate:"
    echo "$CA_CERT"
    echo "$CA_CERT" | pbcopy 2>/dev/null || echo "   (Copy the above value)"
else
    echo "   Failed to get CA certificate"
    echo "   Try: oc config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'"
fi
echo ""

# Get SSH Key
echo "3. vm_ssh_public_key (Terraform Variable - Sensitive):"
SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"
if [ ! -f "$SSH_KEY_FILE" ]; then
    SSH_KEY_FILE="$HOME/.ssh/id_ed25519.pub"
fi

if [ -f "$SSH_KEY_FILE" ]; then
    echo "   SSH Public Key:"
    cat "$SSH_KEY_FILE"
    cat "$SSH_KEY_FILE" | pbcopy 2>/dev/null || echo "   (Copy the above value)"
else
    echo "   No SSH public key found at ~/.ssh/id_rsa.pub or ~/.ssh/id_ed25519.pub"
    echo "   Generate one with: ssh-keygen -t rsa -b 4096 -C 'your_email@example.com'"
fi
echo ""

echo "=========================================="
echo "Next Steps:"
echo "1. Copy the values above"
echo "2. Go to Terraform Cloud workspace:"
echo "   https://app.terraform.io/app/ocp-virt-tfe-demo/workspaces/openshift-cluster-management"
echo "3. Navigate to Variables and update:"
echo "   - KUBE_TOKEN (Environment, Sensitive)"
echo "   - KUBE_CLUSTER_CA_CERT_DATA (Environment)"
echo "   - vm_ssh_public_key (Terraform, Sensitive)"
echo "4. Then run: terraform init && terraform apply"
echo "=========================================="

