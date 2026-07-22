# ==============================================================================
# 3-HOST-PROJECTS — Shared VPC Host Projects
# ==============================================================================
# Creates:
#   1. hub host project       → fldr-network       (shared VPC host for hub)
#   2. dev host project       → fldr-development    (shared VPC host for dev)
#
# This is the ONLY stage that creates host projects — never inline project
# creation elsewhere (single source of truth via modules/project).
#
# Consumes remote state from:
#   - 0-bootstrap  → terraform_sa_email
#   - 2-folders    → folder_ids map
#
# Output consumed by:
#   - 4-networks (VPC, subnets, NAT, etc.)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. REMOTE STATE — Read outputs from upstream stages
# ------------------------------------------------------------------------------
data "terraform_remote_state" "bootstrap" {
  backend = "gcs"

  config = {
    bucket = "foundation-tf-state-bootstrap"
    prefix = "0-bootstrap"
  }
}

data "terraform_remote_state" "folders" {
  backend = "gcs"

  config = {
    bucket = "foundation-tf-state-bootstrap"
    prefix = "2-folders"
  }
}

# ------------------------------------------------------------------------------
# 2. LOCALS
# ------------------------------------------------------------------------------
locals {
  terraform_sa_email = data.terraform_remote_state.bootstrap.outputs.terraform_sa_email
  folder_ids         = data.terraform_remote_state.folders.outputs.folder_ids

  # Default APIs every host project needs (shared VPC foundation)
  default_host_apis = [
    "compute.googleapis.com",
    "dns.googleapis.com",
  ]

  # Host project definitions — single source of truth
  host_projects = {
    hub = {
      name       = "prj-hub-host"
      project_id = "${var.project_prefix}-hub-host"
      folder_key = "fldr-network"
    }
    dev = {
      name       = "prj-dev-host"
      project_id = "${var.project_prefix}-dev-host"
      folder_key = "fldr-development"
    }
  }
}

# ------------------------------------------------------------------------------
# 3. CREATE HOST PROJECTS (via reusable module)
# ------------------------------------------------------------------------------
module "host_project" {
  for_each = local.host_projects
  source   = "../modules/project"

  name            = each.value.name
  project_id      = each.value.project_id
  org_id          = var.org_id
  billing_account = var.billing_account
  folder_id       = local.folder_ids[each.value.folder_key]

  activate_apis = lookup(
    var.host_project_apis,
    each.key,
    local.default_host_apis,
  )
}
