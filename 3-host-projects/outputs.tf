# ==============================================================================
# 3-HOST-PROJECTS — outputs consumed by downstream networking / service stages
# ==============================================================================

output "project_ids" {
  description = "Map of host project key to project ID (hub/dev)"
  value = {
    hub = module.host_project["hub"].project_id
    dev = module.host_project["dev"].project_id
  }
}

output "project_numbers" {
  description = "Map of host project key to numeric project number"
  value = {
    hub = module.host_project["hub"].project_number
    dev = module.host_project["dev"].project_number
  }
}

output "host_projects" {
  description = "All host project module outputs (keyed by hub/dev)"
  value       = module.host_project
}
