# RHEL 9 VM Deployment on OpenShift

This Terraform configuration deploys a Red Hat Enterprise Linux 9 virtual machine on OpenShift using OpenShift Virtualization (KubeVirt).

## Prerequisites

1. **OpenShift Virtualization Installed**: The cluster must have OpenShift Virtualization (CNV) operator installed
2. **Terraform Cloud Workspace**: This configuration is set to use the `openshift-cluster-management` workspace
3. **Authentication**: The workspace must have `KUBE_HOST`, `KUBE_TOKEN`, and `KUBE_CLUSTER_CA_CERT_DATA` variables configured
4. **Storage Class**: Ensure you have a storage class available for VM disk creation

## Configuration

### Variables

Key variables you may want to customize:

- `vm_name`: Name of the VM (default: `rhel9-vm`)
- `vm_namespace`: Namespace for the VM (default: `rhel9-vms`)
- `vm_cpu_cores`: Number of CPU cores (default: `2`)
- `vm_memory`: Memory request (default: `4Gi`)
- `vm_disk_size`: Root disk size (default: `30Gi`)
- `vm_image_url`: RHEL 9 image URL (default: `quay.io/containerdisks/rhel9:latest` - public, no auth required)
- `vm_ssh_public_key`: SSH public key for VM access (required, sensitive)

### Setting Variables in Terraform Cloud

1. Go to your workspace: `openshift-cluster-management`
2. Navigate to **Variables**
3. Add Terraform variables:
   - `vm_ssh_public_key` (Terraform variable, sensitive)
   - Override any other defaults as needed

## Files

- `main.tf`: Main configuration using DataVolume (recommended for production)
- `main-simple.tf`: Simpler configuration using containerDisk (easier to start)
- `variables.tf`: Variable definitions
- `outputs.tf`: Output values
- `cloud-init.yaml`: Cloud-init template for VM initialization

**Note**: You can use either `main.tf` (with DataVolume) or `main-simple.tf` (with containerDisk). Rename your chosen file to `main.tf` or adjust the configuration accordingly.

## Usage

### Choose Your Configuration

1. **DataVolume approach** (`main.tf`): Creates a PersistentVolumeClaim for the VM disk. Better for production workloads with persistent storage.
2. **ContainerDisk approach** (`main-simple.tf`): Uses a container image directly. Simpler but ephemeral storage.

### Initialize Terraform

```bash
terraform init
```

### Plan Deployment

```bash
terraform plan
```

### Apply Configuration

```bash
terraform apply
```

### Access the VM

After deployment, you can access the VM using:

```bash
# Get VM console URL
oc get vmi rhel9-vm -n rhel9-vms

# Connect via SSH (if network is configured)
# Use the credentials from cloud-init or your SSH key
```

## Customization

### Different RHEL 9 Image

To use a different RHEL 9 image, update the `vm_image_url` variable:

**For DataVolume approach** (`main.tf`):
```hcl
variable "vm_image_url" {
  default = "registry.redhat.io/rhel9/rhel-bootc:latest"
}
```

**For ContainerDisk approach** (`main-simple.tf`):
```hcl
variable "vm_image_url" {
  default = "quay.io/containerdisks/rhel9:latest"
}
```

**Note**: For containerDisk, you need images specifically built for containerDisk format. For DataVolume, you can use standard container images.

### Storage Class

If your cluster requires a specific storage class, set the `vm_storage_class` variable:

```hcl
variable "vm_storage_class" {
  default = "fast-ssd"
}
```

### Network Configuration

The VM is configured with a default pod network. To customize networking, modify the `networks` and `interfaces` sections in `main.tf`.

## Troubleshooting

### VM Not Starting

1. Check VM status:
   ```bash
   oc get vm rhel9-vm -n rhel9-vms
   oc get vmi rhel9-vm -n rhel9-vms
   ```

2. Check events:
   ```bash
   oc describe vm rhel9-vm -n rhel9-vms
   ```

3. Check DataVolume status:
   ```bash
   oc get dv -n rhel9-vms
   ```

### Storage Issues

If the DataVolume fails to create:
1. Verify storage class exists: `oc get storageclass`
2. Check PVC status: `oc get pvc -n rhel9-vms`
3. Verify sufficient storage quota

### Image Pull Issues

**Default Configuration**: The default image (`quay.io/containerdisks/rhel9:latest`) is public and requires no authentication.

If you want to use Red Hat registry images (`registry.redhat.io`) instead:

1. **Create a pull secret** for Red Hat Registry:
   ```bash
   # Get your Red Hat Customer Portal credentials from: https://access.redhat.com/RegistryAuthentication
   oc create secret docker-registry redhat-registry-pull-secret \
     --docker-server=registry.redhat.io \
     --docker-username=<your-redhat-username> \
     --docker-password=<your-redhat-password> \
     -n rhel9-vms
   ```

2. **Set the Terraform variables** in Terraform Cloud:
   - Variable name: `vm_registry_pull_secret`
   - Variable value: `redhat-registry-pull-secret` (or your secret name)
   - Variable name: `vm_image_url`
   - Variable value: `registry.redhat.io/rhel9/rhel-bootc:latest`
   - Type: Terraform variables

3. Verify network connectivity to the registry

## Cleanup

To destroy the VM:

```bash
terraform destroy
```

This will remove:
- The VirtualMachine
- The DataVolume
- The namespace (if empty)

