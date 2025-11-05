output "vm_name" {
  description = "Name of the created VirtualMachine"
  value       = kubernetes_manifest.rhel9_vm.manifest.metadata.name
}

output "vm_namespace" {
  description = "Namespace where the VM was created"
  value       = kubernetes_manifest.rhel9_vm.manifest.metadata.namespace
}

output "vm_status" {
  description = "Current status of the VirtualMachine"
  value       = try(kubernetes_manifest.rhel9_vm.object.status, null)
}

output "vm_ready" {
  description = "Whether the VM is ready"
  value       = try(kubernetes_manifest.rhel9_vm.object.status.ready, false)
}

output "vm_created" {
  description = "Whether the VM was successfully created"
  value       = kubernetes_manifest.rhel9_vm.object != null
}

