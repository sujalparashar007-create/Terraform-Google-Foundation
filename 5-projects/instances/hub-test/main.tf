# ==============================================================================
# 5-PROJECTS / hub-test -- VM in Hub Host Project for validation
# ==============================================================================
# Deploys a compute VM directly in the hub host project (foundation-hub-host-01)
# to validate hub-side networking: IAP SSH, DNS resolution, and connectivity.
# ==============================================================================

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

data "terraform_remote_state" "networks" {
  backend = "gcs"
  config = {
    bucket = "foundation-tf-state-bootstrap"
    prefix = "4-networks-hub-and-spoke"
  }
}

locals {
  terraform_sa_email = data.terraform_remote_state.bootstrap.outputs.terraform_sa_email
  hub_project_id     = data.terraform_remote_state.host_projects.outputs.project_ids["hub"]
  hub_subnet         = data.terraform_remote_state.networks.outputs.hub_subnet_self_link
}

# ------------------------------------------------------------------------------
# VM in Hub Host Project
# ------------------------------------------------------------------------------
resource "google_compute_instance" "vm" {
  project      = local.hub_project_id
  name         = "vm-hub-test"
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
    subnetwork = local.hub_subnet
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

# ------------------------------------------------------------------------------
# IAM -- Grant SSH access via IAP + OS Login
# ------------------------------------------------------------------------------
resource "google_project_iam_member" "iap_tunnel" {
  for_each = toset(var.vm_operators)
  project  = local.hub_project_id
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "user:${each.key}"
}

resource "google_project_iam_member" "os_login" {
  for_each = toset(var.vm_operators)
  project  = local.hub_project_id
  role     = "roles/compute.osLogin"
  member   = "user:${each.key}"
}

resource "google_project_iam_member" "compute_instance_user" {
  for_each = toset(var.vm_operators)
  project  = local.hub_project_id
  role     = "roles/compute.instanceAdmin.v1"
  member   = "user:${each.key}"
}
