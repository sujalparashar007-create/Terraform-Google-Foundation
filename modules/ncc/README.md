# ncc -- Network Connectivity Center Hub-and-Spoke

Creates a central NCC hub and attaches VPC spokes for full-mesh connectivity
across all attached VPCs without traditional VPC peering.

## Usage

`hcl
module "ncc" {
  source = "../modules/ncc"

  hub_project_id = "my-hub-project"
  hub_name       = "ncc-hub"
  region         = "us-east1"

  vpc_spokes = {
    hub = {
      project_id    = "my-hub-project"
      vpc_self_link = module.hub.vpc_self_link
    }
    dev = {
      project_id    = "my-dev-project"
      vpc_self_link = module.spoke["dev"].vpc_self_link
    }
  }

  labels = {
    environment = "shared"
    managed_by  = "terraform"
  }
}
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| hub_project_id | string | required | Project ID for the NCC hub |
| hub_name | string | ncc-hub | NCC hub name |
| region | string | required | GCP region (for labels) |
| vpc_spokes | map(object) | required | Map of spoke name to {project_id, vpc_self_link} |
| labels | map(string) | {} | Resource labels |

## Outputs

| Name | Description |
|------|-------------|
| hub_id | NCC hub resource ID |
| hub_name | NCC hub resource name |
| hub_state | Current state of the hub |
| spoke_ids | Map of spoke name to ID |
| spoke_names | Map of spoke name to resource name |