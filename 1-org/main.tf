# ==============================================================================
# 1-ORG — Organization-level Resources
# ==============================================================================
# Creates:
#   1. Hierarchical firewall policy via modules/org-policy (7 enterprise rules)
#   2. Parameterized org-level IAM bindings
#
# Consumes from 0-bootstrap remote state:
#   - terraform_sa_email  → provider impersonation
#   - state_bucket_name   → backend "gcs" block
#   - seed_project_id     → reference only
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
}

# ------------------------------------------------------------------------------
# 2. HIERARCHICAL FIREWALL POLICY (reusable module)
# ------------------------------------------------------------------------------
module "org_policy" {
  source = "../modules/org-policy"

  org_id         = var.org_id
  project_prefix = var.project_prefix
  rules          = local.firewall_rules
}

# ------------------------------------------------------------------------------
# 3. ORG-LEVEL IAM BINDINGS (parameterized)
# ------------------------------------------------------------------------------
resource "google_organization_iam_member" "bindings" {
  for_each = var.org_iam_bindings

  org_id = var.org_id
  role   = each.value.role
  member = each.value.member
}
