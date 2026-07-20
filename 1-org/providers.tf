# ── 1-org provider — impersonates the Terraform SA created by 0-bootstrap.
# The SA email is read from the 0-bootstrap remote state (GCS backend).

provider "google" {
  region                      = var.region
  impersonate_service_account = local.terraform_sa_email
}
