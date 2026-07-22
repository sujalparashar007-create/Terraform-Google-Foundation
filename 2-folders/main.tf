# ==============================================================================
# 2-FOLDERS — Organization Folder Hierarchy
# ==============================================================================
# Creates:
#   1. Four top-level folders under the organization:
#      - fldr-network        (shared VPC host projects)
#      - fldr-development    (dev/test sandbox projects)
#      - fldr-nonproduction  (staging/UAT projects)
#      - fldr-production     (prod projects)
#   2. Folder-level IAM bindings (parameterized)
#
# Consumes from 0-bootstrap remote state:
#   - terraform_sa_email  → provider impersonation
#
# This stage CAN run in parallel with 1-org (no dependencies between them).
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. REMOTE STATE — Read outputs from 0-bootstrap
# ------------------------------------------------------------------------------
data "terraform_remote_state" "bootstrap" {
  backend = "gcs"

  config = {
    bucket = "foundation-tf-state-bootstrap"
    prefix = "0-bootstrap"
  }
}

locals {
  terraform_sa_email = data.terraform_remote_state.bootstrap.outputs.terraform_sa_email

  # The four foundation folders
  folder_names = toset([
    "fldr-network",
    "fldr-development",
    "fldr-nonproduction",
    "fldr-production",
  ])
}

# ------------------------------------------------------------------------------
# 2. CREATE FOLDERS (via reusable module)
# ------------------------------------------------------------------------------
module "folders" {
  source = "../modules/folder"

  parent     = "organizations/${var.org_id}"
  names      = local.folder_names
  folder_iam = var.folder_iam_bindings
}
