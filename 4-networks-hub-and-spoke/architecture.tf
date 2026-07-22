data "terraform_remote_state" "bootstrap" {
  backend = "gcs"
  config = {
    bucket = "foundation-tf-state-bootstrap"
    prefix = "0-bootstrap"
  }
}
data "terraform_remote_state" "host_projects" {
  backend = "gcs"
  config = {
    bucket = "foundation-tf-state-bootstrap"
    prefix = "3-host-projects"
  }
}
locals {
  terraform_sa_email = data.terraform_remote_state.bootstrap.outputs.terraform_sa_email
  project_ids        = data.terraform_remote_state.host_projects.outputs.project_ids
  use_peering                = var.connectivity_model == "peering"
  use_ncc                    = var.connectivity_model == "ncc"
  use_distributed_nat        = var.egress_model == "distributed_nat"
  use_centralized_inspection = var.egress_model == "centralized_inspection"
}
