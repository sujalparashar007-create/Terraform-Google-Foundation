# peering -- VPC Network Peering (Bidirectional)

Creates bidirectional VPC peering between a hub and a spoke VPC with optional
custom route export/import.

## Usage

`hcl
module "peering" {
  source = "../modules/peering"

  hub_vpc_self_link    = module.hub.vpc_self_link
  spoke_vpc_self_link  = module.spoke["dev"].vpc_self_link
  env_name             = "dev"
  export_custom_routes = true
  import_custom_routes = true
}
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| hub_vpc_self_link | string | required | Self-link of hub VPC |
| spoke_vpc_self_link | string | required | Self-link of spoke VPC |
| env_name | string | required | Environment name for peering naming |
| export_custom_routes | bool | false | Export custom routes |
| import_custom_routes | bool | false | Import custom routes |

## Outputs

| Name | Description |
|------|-------------|
| hub_peering_name | Hub-to-spoke peering name |
| spoke_peering_name | Spoke-to-hub peering name |