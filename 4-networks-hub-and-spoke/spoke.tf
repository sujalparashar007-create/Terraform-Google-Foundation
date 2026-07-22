# ==============================================================================
# SPOKES -- dev only (modules/spoke, workload_type driven)
# ==============================================================================
module "spoke" {
  for_each = var.environments
  source   = "../modules/spoke"

  project_id    = local.project_ids[each.key]
  region        = var.region
  env_name      = each.key
  spoke_cidr    = each.value.spoke_cidr
  vpc_name      = each.value.vpc_name
  subnet_name   = each.value.subnet_name
  subnet_cidr   = each.value.subnet_cidr
  workload_type = each.value.workload_type
  pod_cidr      = each.value.pod_cidr
  svc_cidr      = each.value.svc_cidr
}
