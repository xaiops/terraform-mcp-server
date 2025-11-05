variable "vm_name" {
  type        = string
  description = "Name of the RHEL 9 VirtualMachine"
  default     = "rhel9-vm"
}

variable "vm_namespace" {
  type        = string
  description = "Namespace where the VM will be created"
  default     = "rhel9-vms"
}

variable "vm_running" {
  type        = bool
  description = "Whether the VM should start automatically"
  default     = true
}

variable "vm_cpu_cores" {
  type        = number
  description = "Number of CPU cores"
  default     = 2
}

variable "vm_cpu_sockets" {
  type        = number
  description = "Number of CPU sockets"
  default     = 1
}

variable "vm_cpu_threads" {
  type        = number
  description = "Number of CPU threads per core"
  default     = 1
}

variable "vm_memory" {
  type        = string
  description = "Memory request for the VM (e.g., '4Gi', '8Gi')"
  default     = "4Gi"
}

variable "vm_memory_limit" {
  type        = string
  description = "Memory limit for the VM (e.g., '4Gi', '8Gi')"
  default     = "4Gi"
}

variable "vm_cpu_limit" {
  type        = string
  description = "CPU limit for the VM"
  default     = "2"
}

variable "vm_size" {
  type        = string
  description = "Size label for the VM (tiny, small, medium, large, etc.)"
  default     = "medium"
}

variable "vm_disk_size" {
  type        = string
  description = "Size of the root disk (e.g., '30Gi', '50Gi')"
  default     = "30Gi"
}

variable "vm_storage_class" {
  type        = string
  description = "Storage class for the VM disk. Leave empty to use the cluster's default storage class. Available: ocs-external-storagecluster-ceph-rbd (default), ocs-external-storagecluster-ceph-rbd-immediate"
  default     = ""
}

variable "vm_image_url" {
  type        = string
  description = "Container image URL for RHEL 9. Public image: 'quay.io/containerdisks/rhel9:latest' (no auth required) or Red Hat registry: 'registry.redhat.io/rhel9/rhel-bootc:latest' (requires pull secret)"
  default     = "quay.io/containerdisks/rhel9:latest"
}

variable "vm_ssh_public_key" {
  type        = string
  description = "SSH public key for VM access"
  sensitive   = true
  default     = ""
}

variable "vm_registry_pull_secret" {
  type        = string
  description = "Name of the Secret containing registry pull credentials (e.g., for registry.redhat.io). Create with: oc create secret docker-registry <name> --docker-server=registry.redhat.io --docker-username=<username> --docker-password=<password> -n <namespace>"
  default     = ""
}

