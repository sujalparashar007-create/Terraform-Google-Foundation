# ==============================================================================
# CONNECTIVITY -- strategy layer: peering OR ncc
# ==============================================================================

module "peering" {
  for_each = local.use_peering ? var.environments : {}
  source   = "../modules/peering"

  hub_vpc_self_link    = module.hub.vpc_self_link
  spoke_vpc_self_link  = module.spoke[each.key].vpc_self_link
  env_name             = each.key
  export_custom_routes = true
  import_custom_routes = true
}

# ==============================================================================
# NCC -- Network Connectivity Center hub-and-spoke
# ==============================================================================
# Deploy when connectivity_model == "ncc". Creates a central NCC hub and
# attaches all VPCs (hub + spokes) as NCC spokes for full-mesh connectivity.
# Each spoke must reside in its VPC's own project (GCP NCC requirement).
# ==============================================================================
module "ncc" {
  count  = local.use_ncc ? 1 : 0
  source = "../modules/ncc"

  hub_project_id = local.project_ids["hub"]
  hub_name       = "ncc-hub"
  region         = var.region
  vpc_spokes = merge(
    {
      hub = {
        project_id    = local.project_ids["hub"]
        vpc_self_link = module.hub.vpc_self_link
      }
    },
    {
      for k, v in module.spoke : k => {
        project_id    = local.project_ids[k]
        vpc_self_link = v.vpc_self_link
      }
    }
  )
  labels = {
    environment = "shared"
    managed_by  = "terraform"
  }
}
