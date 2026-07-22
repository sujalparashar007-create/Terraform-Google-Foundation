# ==============================================================================
# EGRESS -- strategy layer: distributed_nat OR centralized_inspection
# ==============================================================================

resource "google_compute_router_nat" "spoke" {
  for_each = local.use_distributed_nat ? {
    for k, v in var.environments : k => v if v.nat_enabled
  } : {}

  project = local.project_ids[each.key]
  name    = "nat-${each.key}"
  region  = var.region
  router  = google_compute_router.spoke[each.key].name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_router" "spoke" {
  for_each = local.use_distributed_nat ? {
    for k, v in var.environments : k => v if v.nat_enabled
  } : {}

  project = local.project_ids[each.key]
  name    = "cr-${each.key}-${var.region}"
  region  = var.region
  network = module.spoke[each.key].vpc_self_link

  bgp { asn = 64515 }
}

# Centralized inspection (placeholder)
# module "centralized_egress" { count = local.use_centralized_inspection ? 1 : 0; ... }
