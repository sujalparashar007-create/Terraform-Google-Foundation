# ==============================================================================
# 2-FOLDERS — outputs consumed by downstream environment / network stages
# ==============================================================================

output "folder_ids" {
  description = "Map of logical folder name to numeric folder ID"
  value       = module.folders.folder_ids
}

output "folder_names" {
  description = "Map of logical folder name to full resource name (folders/NNN)"
  value       = module.folders.folder_names
}

output "folders" {
  description = "All folder resource objects (keyed by display name)"
  value       = module.folders.folders
}
