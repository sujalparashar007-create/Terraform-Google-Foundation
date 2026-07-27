output "hub_vpc_self_link" {
  description = "Self-link of the hub VPC"
  value       = module.hub.vpc_self_link
}
output "hub_subnet_self_link" {
  description = "Self-link of the hub subnet"
  value       = module.hub.subnet_self_link
}
output "spoke_subnets" {
  description = "Map of env name to spoke subnet self-link"
  value       = { for k, v in module.spoke : k => v.subnet_self_link }
}
output "spoke_vpcs" {
  description = "Map of env name to spoke VPC self-link"
  value       = { for k, v in module.spoke : k => v.vpc_self_link }
}
output "connectivity_model" {
  description = "Chosen connectivity model"
  value       = var.connectivity_model
}
output "egress_model" {
  description = "Chosen egress model"
  value       = var.egress_model
}

# ==============================================================================
# NCC outputs (populated only when connectivity_model == "ncc")
# ==============================================================================
output "ncc_hub_id" {
  description = "NCC hub resource ID (null when using peering)"
  value       = try(module.ncc[0].hub_id, null)
}
output "ncc_hub_name" {
  description = "NCC hub resource name (null when using peering)"
  value       = try(module.ncc[0].hub_name, null)
}
output "ncc_spoke_names" {
  description = "Map of spoke names attached to NCC hub (null when using peering)"
  value       = try(module.ncc[0].spoke_names, null)
}
