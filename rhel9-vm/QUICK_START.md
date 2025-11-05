# Quick Start - Deploy RHEL 9 VM

## Step 1: Login to Terraform Cloud

Run this command and follow the prompts:

```bash
cd /Users/chrhamme/Desktop/terraform-mcp-server/rhel9-vm
terraform login
```

This will:
1. Open your browser to generate a token
2. Ask you to paste the token back
3. Store it for future use

**Alternative**: If you have a Terraform Cloud token, you can create the credentials file manually:

```bash
mkdir -p ~/.terraform.d
cat > ~/.terraform.d/credentials.tfrc.json <<EOF
{
  "credentials": {
    "app.terraform.io": {
      "token": "YOUR_TOKEN_HERE"
    }
  }
}
EOF
```

## Step 2: Initialize Terraform

```bash
terraform init
```

## Step 3: Preview Changes

```bash
terraform plan
```

## Step 4: Deploy

```bash
terraform apply
```

Type `yes` when prompted to confirm.

## Verify Deployment

After deployment completes:

```bash
# Check VM status
oc get vm rhel9-vm -n rhel9-vms

# Check running VM instance
oc get vmi rhel9-vm -n rhel9-vms

# Check DataVolume (disk)
oc get dv rhel9-vm-rootdisk -n rhel9-vms
```

## Troubleshooting

If you encounter issues:
1. Check that all workspace variables are set in Terraform Cloud
2. Verify OpenShift Virtualization is installed: `oc get csv -n openshift-cnv`
3. Check storage class: `oc get storageclass`
4. Review Terraform logs for detailed errors

