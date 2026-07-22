output "vm_self_link" {
  description = "Self-link of the test VM"
  value       = google_compute_instance.vm.self_link
}

output "vm_internal_ip" {
  description = "Internal IP of the test VM"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "service_project_id" {
  description = "Project ID of the service project"
  value       = module.service_project.project_id
}
