# ==============================================================================
# HUB -- VPC + Subnet + Cloud Router (modules/hub, single source of truth)
# ==============================================================================
module "hub" {
  source = "../modules/hub"

  project_id  = local.project_ids["hub"]
  region      = var.region
  hub_cidr    = var.hub_cidr
  subnet_cidr = var.hub_subnet_cidr

  vpc_name    = "vpc-hub"
  subnet_name = "sb-hub-${var.region}"
  router_name = "cr-hub-${var.region}"
}
