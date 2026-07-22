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

# NCC path (placeholder)
# module "ncc" { count = local.use_ncc ? 1 : 0; source = "../modules/ncc"; ... }
