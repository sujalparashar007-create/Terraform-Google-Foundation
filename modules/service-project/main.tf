# ==============================================================================
# MODULE: service-project
# ==============================================================================
# Creates a service project (via modules/project), enables required APIs,
# attaches it as a Shared VPC service project to the spoke host project,
# and grants networkUser IAM on the target subnet.
# ==============================================================================

locals {
  default_apis = ["compute.googleapis.com"]
  all_apis     = distinct(concat(local.default_apis, var.activate_apis))
}

module "project" {
  source = "../project"

  name            = var.service_project_name
  project_id      = var.service_project_id
  org_id          = var.org_id
  folder_id       = var.folder_id
  billing_account = var.billing_account
  activate_apis   = local.all_apis
}

resource "google_compute_shared_vpc_service_project" "attachment" {
  host_project    = var.host_project_id
  service_project = module.project.project_id

  depends_on = [module.project]
}

resource "google_compute_subnetwork_iam_member" "network_user" {
  project    = var.host_project_id
  region     = var.region
  subnetwork = element(split("/", var.subnet_self_link), length(split("/", var.subnet_self_link)) - 1)
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${google_service_account.compute_sa.email}"
}

data "google_project" "service" {
  project_id = module.project.project_id
  depends_on = [module.project]
}

resource "google_service_account" "compute_sa" {
  project      = module.project.project_id
  account_id   = "svc-vm-default"
  display_name = "Default compute service account for service project"

  depends_on = [module.project]
}
