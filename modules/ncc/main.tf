# ==============================================================================
# MODULE: ncc - Network Connectivity Center hub-and-spoke
# ==============================================================================
# Creates a central NCC hub and attaches VPC spokes to enable full-mesh
# connectivity across all attached VPCs without traditional VPC Peering.
#
# Resources:
#   - google_network_connectivity_hub   (1 x global hub)
#   - google_network_connectivity_spoke (N x VPC spokes attached to the hub)
#
# Notes:
#   - NCC hub is global; created in the hub project.
#   - Each VPC spoke must live in its VPC's own project (GCP requirement).
#   - VPC spokes require location = "global" (not regional).
# ==============================================================================

# ------------------------------------------------------------------------------
# NCC Hub - global resource, one per connectivity domain
# ------------------------------------------------------------------------------
resource "google_network_connectivity_hub" "hub" {
  project     = var.hub_project_id
  name        = var.hub_name
  description = "NCC hub for hub-and-spoke network connectivity"
  labels      = var.labels
}

# ------------------------------------------------------------------------------
# NCC Spokes - one per VPC, created in each VPC's own project
# ------------------------------------------------------------------------------
resource "google_network_connectivity_spoke" "spokes" {
  for_each = var.vpc_spokes

  project  = each.value.project_id
  name     = "ncc-spoke-${each.key}"
  location = "global"
  hub      = google_network_connectivity_hub.hub.id
  labels   = var.labels

  linked_vpc_network {
    uri                   = each.value.vpc_self_link
    exclude_export_ranges = []
  }
}
