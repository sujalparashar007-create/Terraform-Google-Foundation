# 1-org -- Organization-level Resources

Deploys a hierarchical firewall policy with 7 enterprise rules and
parameterized org-level IAM bindings.

## Resources

- Hierarchical firewall policy (attached to org)
- 7 org-level firewall rules (SSH, scanner, monitoring, backup)
- Optional org-level IAM bindings

## Depends On

- 0-bootstrap (reads terraform_sa_email from remote state)

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
| project_prefix | string | foundation | Prefix for resource naming |
| region | string | us-east1 | Default region |
| org_iam_bindings | map(object) | {} | Org-level IAM bindings |
| corp_ssh_range | string | 198.51.100.0/24 | Corporate SSH CIDR |
| vpn_ssh_range | string | 198.51.101.0/24 | VPN SSH CIDR |
| bastion_range | string | 10.10.10.0/24 | Bastion CIDR |
| vuln_scanner_range | string | 10.20.0.0/24 | Vulnerability scanner CIDR |
| monitoring_range | string | 10.30.0.0/24 | Monitoring CIDR |
| backup_range | string | 10.40.0.0/24 | Backup CIDR |

## Outputs

| Name | Description |
|------|-------------|
| policy_id | Hierarchical firewall policy ID |
| policy_name | Policy short name |