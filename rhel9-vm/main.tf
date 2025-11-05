terraform {
  required_version = ">= 1.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
  
  cloud {
    organization = "ocp-virt-tfe-demo"
    workspaces {
      name = "openshift-cluster-management"
    }
  }
}

provider "kubernetes" {
  # Authentication via KUBE_HOST, KUBE_TOKEN, and KUBE_CLUSTER_CA_CERT_DATA
  # environment variables set in Terraform Cloud workspace
}

# Local value to ensure registry URL has proper docker:// scheme for CDI DataVolume
locals {
  # Add docker:// prefix if URL doesn't already have a scheme
  vm_image_url_formatted = can(regex("^[a-z]+://", var.vm_image_url)) ? var.vm_image_url : "docker://${var.vm_image_url}"
}

# Create namespace for the VM
resource "kubernetes_namespace" "rhel9_vm" {
  metadata {
    name = var.vm_namespace
    labels = {
      app = "rhel9-vm"
    }
  }
}

# Create Secret for cloud-init userData (required for data > 2048 bytes)
resource "kubernetes_secret" "rhel9_vm_cloudinit" {
  depends_on = [kubernetes_namespace.rhel9_vm]
  
  metadata {
    name      = "${var.vm_name}-cloudinit"
    namespace = var.vm_namespace
  }
  
  data = {
    userdata = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      hostname = var.vm_name
      ssh_key  = var.vm_ssh_public_key != "" ? var.vm_ssh_public_key : "# No SSH key provided"
    }))
  }
  
  type = "Opaque"
}

# Create RHEL 9 VirtualMachine using kubernetes_manifest
resource "kubernetes_manifest" "rhel9_vm" {
  depends_on = [kubernetes_namespace.rhel9_vm, kubernetes_secret.rhel9_vm_cloudinit]
  
  manifest = {
    apiVersion = "kubevirt.io/v1"
    kind       = "VirtualMachine"
    metadata = {
      name      = var.vm_name
      namespace = var.vm_namespace
      labels = {
        app                 = "rhel9-vm"
        "kubevirt.io/vm"    = var.vm_name
        "vm.kubevirt.io/os" = "rhel9"
      }
      annotations = {
        "description" = "RHEL 9 Virtual Machine managed by Terraform"
      }
    }
    spec = {
      running = var.vm_running
      template = {
        metadata = {
          labels = {
            "kubevirt.io/domain" = var.vm_name
            "kubevirt.io/size"   = var.vm_size
          }
        }
        spec = {
          domain = {
            cpu = {
              cores   = var.vm_cpu_cores
              sockets = var.vm_cpu_sockets
              threads = var.vm_cpu_threads
            }
            devices = {
              disks = [
                {
                  name = "rootdisk"
                  disk = {
                    bus = "virtio"
                  }
                },
                {
                  name = "cloudinitdisk"
                  disk = {
                    bus = "virtio"
                  }
                }
              ]
              interfaces = [
                {
                  name = "default"
                  masquerade = {}
                }
              ]
            }
            machine = {
              type = "q35"
            }
            resources = {
              requests = {
                memory = var.vm_memory
                cpu    = var.vm_cpu_cores
              }
              limits = {
                memory = var.vm_memory_limit
                cpu    = var.vm_cpu_limit
              }
            }
          }
          networks = [
            {
              name = "default"
              pod = {}
            }
          ]
          volumes = [
            {
              name = "rootdisk"
              dataVolume = {
                name = "${var.vm_name}-rootdisk"
              }
            },
            {
              name = "cloudinitdisk"
              cloudInitNoCloud = {
                secretRef = {
                  name = kubernetes_secret.rhel9_vm_cloudinit.metadata[0].name
                }
              }
            }
          ]
        }
      }
      dataVolumeTemplates = [
        {
          metadata = {
            name = "${var.vm_name}-rootdisk"
          }
          spec = {
            source = {
              registry = merge(
                {
                  url = local.vm_image_url_formatted
                },
                var.vm_registry_pull_secret != "" ? {
                  secretRef = var.vm_registry_pull_secret
                } : {}
              )
            }
            pvc = merge(
              {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.vm_disk_size
                  }
                }
              },
              var.vm_storage_class != "" ? { storageClassName = var.vm_storage_class } : {}
            )
          }
        }
      ]
    }
  }
  
  wait {
    fields = {
      "status.ready" = "true"
    }
  }
  
  timeouts {
    create = "30m"
    update = "20m"
    delete = "10m"
  }
  
  computed_fields = ["metadata.annotations", "metadata.labels", "status"]
}

