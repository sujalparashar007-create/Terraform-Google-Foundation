# firewall -- VPC Firewall Rules Factory

Creates firewall rules on a VPC from a typed map variable. Supports allow/deny,
INGRESS/EGRESS, source/target tags, and service accounts.

## Usage

`hcl
module "firewall" {
  source = "../modules/firewall"

  project_id    = "my-project"
  vpc_self_link = module.hub.vpc_self_link

  rules = {
    allow-iap-ssh = {
      name          = "allow-iap-ssh"
      description   = "Allow IAP SSH from GCP ranges"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["35.235.240.0/20"]
      allow         = [{ protocol = "tcp", ports = ["22"] }]
    }
  }
}
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| project_id | string | required | GCP project ID |
| vpc_self_link | string | required | Self-link of the VPC |
| rules | map(object) | {} | Map of firewall rules |

## Outputs

| Name | Description |
|------|-------------|
| rule_ids | Map of firewall rule IDs |