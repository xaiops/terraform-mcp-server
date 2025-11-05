# Quick Deploy Guide - RHEL 9 VM on OpenShift

## Prerequisites Setup

Before deploying, you need to complete the authentication setup in Terraform Cloud.

### Step 1: Get Your OpenShift Token

Run this command to get your authentication token:

```bash
oc whoami -t
```

Copy the token output.

### Step 2: Get the CA Certificate

Run this command to get the base64-encoded CA certificate:

```bash
oc config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'
```

Or if you have a kubeconfig file:

```bash
cat ~/.kube/config | grep certificate-authority-data | awk '{print $2}' | head -1
```

Copy the base64-encoded certificate output.

### Step 3: Get Your SSH Public Key

Run this command to get your SSH public key:

```bash
cat ~/.ssh/id_rsa.pub
```

Or if you use a different key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire SSH public key.

### Step 4: Update Terraform Cloud Variables

Go to your Terraform Cloud workspace: https://app.terraform.io/app/ocp-virt-tfe-demo/workspaces/openshift-cluster-management

Navigate to **Variables** and update:

1. **KUBE_TOKEN** (Environment Variable, Sensitive):
   - Value: Paste the token from Step 1
   - Mark as Sensitive: ✓

2. **KUBE_CLUSTER_CA_CERT_DATA** (Environment Variable):
   - Value: Paste the CA certificate from Step 2
   - Mark as Sensitive: ✗

3. **vm_ssh_public_key** (Terraform Variable, Sensitive):
   - Value: Paste your SSH public key from Step 3
   - Mark as Sensitive: ✓

## Deployment Options

### Option A: Using Terraform CLI (Recommended)

1. **Install Terraform** (if not already installed):
   - macOS: `brew install terraform`
   - Or download from: https://developer.hashicorp.com/terraform/downloads

2. **Login to Terraform Cloud**:
   ```bash
   cd /Users/chrhamme/Desktop/terraform-mcp-server/rhel9-vm
   terraform login
   ```

3. **Initialize**:
   ```bash
   terraform init
   ```

4. **Plan** (optional, to preview changes):
   ```bash
   terraform plan
   ```

5. **Apply**:
   ```bash
   terraform apply
   ```

### Option B: Using Terraform Cloud UI

1. Go to: https://app.terraform.io/app/ocp-virt-tfe-demo/workspaces/openshift-cluster-management

2. Click **"Actions"** → **"Start new plan"**

3. Terraform Cloud will automatically detect your configuration files if you've uploaded them via VCS or CLI

4. Review and confirm the plan

5. Apply the changes

## Verify Deployment

After deployment, check your VM:

```bash
# Check VM status
oc get vm rhel9-vm -n rhel9-vms

# Check VirtualMachineInstance (running VM)
oc get vmi rhel9-vm -n rhel9-vms

# Check DataVolume (disk)
oc get dv rhel9-vm-rootdisk -n rhel9-vms

# Get VM console URL
oc get vmi rhel9-vm -n rhel9-vms -o jsonpath='{.status.interfaces[0].ipAddress}'
```

## Troubleshooting

If the deployment fails:

1. **Check authentication variables** are set correctly in Terraform Cloud
2. **Verify OpenShift Virtualization** is installed:
   ```bash
   oc get csv -n openshift-cnv | grep kubevirt
   ```
3. **Check storage class** exists:
   ```bash
   oc get storageclass
   ```
4. **Review Terraform Cloud run logs** for detailed error messages

## Next Steps

Once deployed, you can:
- Access the VM console via OpenShift web UI
- SSH into the VM (if network is configured)
- Manage the VM lifecycle with Terraform

