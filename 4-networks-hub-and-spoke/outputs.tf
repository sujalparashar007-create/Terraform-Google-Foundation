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
