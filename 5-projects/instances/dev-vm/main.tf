# ==============================================================================
# 5-PROJECTS / dev-vm � Single VM validation
# ==============================================================================
# Deploys a service project + compute VM in the dev spoke to validate
# end-to-end networking: IAP SSH, egress via NAT, DNS resolution.
# ==============================================================================

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

data "terraform_remote_state" "networks" {
  backend = "gcs"
  config = {
    bucket = "foundation-tf-state-bootstrap"
    prefix = "4-networks-hub-and-spoke"
  }
}

locals {
  terraform_sa_email = data.terraform_remote_state.bootstrap.outputs.terraform_sa_email
  dev_folder_id      = data.terraform_remote_state.folders.outputs.folder_ids["fldr-development"]
  dev_subnet         = data.terraform_remote_state.networks.outputs.spoke_subnets["dev"]
  dev_host_project   = data.terraform_remote_state.host_projects.outputs.project_ids["dev"]
}

# Needs Stage 3 remote state for the dev host project ID
data "terraform_remote_state" "host_projects" {
  backend = "gcs"
  config = {
    bucket = "foundation-tf-state-bootstrap"
    prefix = "3-host-projects"
  }
}

module "service_project" {
  source = "../../../modules/service-project"

  org_id               = var.org_id
  billing_account      = var.billing_account
  folder_id            = local.dev_folder_id
  host_project_id      = local.dev_host_project
  service_project_name = "prj-dev-svc-vm"
  service_project_id   = "${var.project_prefix}-dev-svc-vm"
  subnet_self_link     = local.dev_subnet
  region               = var.region
}

resource "google_compute_instance" "vm" {
  project      = module.service_project.project_id
  name         = "vm-dev-test"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = module.service_project.subnet_self_link
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  service_account {
    email  = module.service_project.compute_sa_email
    scopes = ["cloud-platform"]
  }

  depends_on = [module.service_project]
}
