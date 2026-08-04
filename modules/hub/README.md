# hub -- Hub VPC + Subnet + Cloud Router

Creates a hub VPC network, a single subnet, and a Cloud Router for BGP.
Used as the central hub in a hub-and-spoke topology.

## Usage

`hcl
module "hub" {
  source = "../modules/hub"

  project_id  = "my-hub-project"
  region      = "us-east1"
  hub_cidr    = "10.0.0.0/20"
  subnet_cidr = "10.0.0.0/24"
  vpc_name    = "vpc-hub"
  subnet_name = "sb-hub-us-east1"
  router_name = "cr-hub-us-east1"
  router_asn  = 64514
}
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| project_id | string | required | GCP project ID |
| region | string | required | GCP region |
| hub_cidr | string | 10.0.0.0/20 | Reserved CIDR for hub |
| subnet_cidr | string | 10.0.0.0/24 | Primary subnet CIDR |
| subnet_name | string | sb-hub | Subnet name |
| vpc_name | string | vpc-hub | VPC name |
| router_name | string | cr-hub | Cloud Router name |
| router_asn | number | 64514 | BGP ASN |

## Outputs

| Name | Description |
|------|-------------|
| vpc_self_link | Hub VPC self-link |
| vpc_id | Hub VPC ID |
| vpc_name | Hub VPC name |
| subnet_self_link | Hub subnet self-link |
| subnet_name | Hub subnet name |
| router_self_link | Cloud Router self-link |
| router_name | Cloud Router name |
| region | Deployed region |