# 4-networks-hub-and-spoke -- VPC Networks + Connectivity

Deploys hub and spoke VPCs, subnets, Cloud Routers, Cloud NAT, DNS, and
connectivity (VPC peering or NCC).

## Resources

- Hub VPC + subnet + Cloud Router
- Dev spoke VPC + subnet
- Cloud NAT (dev only, distributed egress)
- VPC peering (bidirectional) or NCC hub-and-spoke
- Cloud DNS policy + private zone
- VPC firewall rules

## Depends On

- 0-bootstrap (terraform_sa_email)
- 3-host-projects (project_ids)

## Connectivity Toggle

Set connectivity_model in terraform.tfvars:
- peering -- traditional bidirectional VPC peering
- 
cc -- Network Connectivity Center full-mesh

## Usage

`ash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| org_id | string | required | Numeric org ID |
| billing_account | string | required | Billing account ID |
| project_prefix | string | foundation | Prefix for project names |
| region | string | us-east1 | Default region |
| connectivity_model | string | peering | peering or ncc |
| egress_model | string | distributed_nat | distributed_nat or centralized_inspection |
| shared_vpc_enabled | bool | true | Enable Shared VPC |
| hub_cidr | string | 10.0.0.0/20 | Hub CIDR |
| hub_subnet_cidr | string | 10.0.0.0/24 | Hub subnet CIDR |
| environments | map(object) | dev | Spoke environment definitions |

## Outputs

| Name | Description |
|------|-------------|
| hub_vpc_self_link | Hub VPC self-link |
| hub_subnet_self_link | Hub subnet self-link |
| spoke_vpc_self_links | Map of spoke VPC self-links |
| spoke_subnets | Map of spoke subnet self-links |