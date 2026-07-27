output "vm_name" {
  description = "Name of the hub test VM"
  value       = google_compute_instance.vm.name
}

output "vm_self_link" {
  description = "Self-link of the hub test VM"
  value       = google_compute_instance.vm.self_link
}

output "vm_internal_ip" {
  description = "Internal IP of the hub test VM"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "hub_project_id" {
  description = "Hub host project ID"
  value       = local.hub_project_id
}
