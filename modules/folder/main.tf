# ==============================================================================
# MODULE: folder — Google Cloud Folder Factory
# ==============================================================================
# Creates one or more folders under a given parent (organization or folder)
# with optional folder-level IAM bindings.
#
# Usage example:
#   module "environment_folders" {
#     source = "../modules/folder"
#     parent = "organizations/123456789"
#     names  = toset(["fldr-dev", "fldr-prod"])
#     folder_iam = {
#       dev_creator = {
#         folder_key = "fldr-dev"
#         role       = "roles/resourcemanager.projectCreator"
#         member     = "group:dev-team@example.com"
#       }
#     }
#   }
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. FOLDERS
# ------------------------------------------------------------------------------
resource "google_folder" "folders" {
  for_each     = var.names
  display_name = each.value
  parent       = var.parent
}

# ------------------------------------------------------------------------------
# 2. FOLDER-LEVEL IAM (optional)
# ------------------------------------------------------------------------------
resource "google_folder_iam_member" "bindings" {
  for_each = var.folder_iam

  folder = google_folder.folders[each.value.folder_key].name
  role   = each.value.role
  member = each.value.member
}
