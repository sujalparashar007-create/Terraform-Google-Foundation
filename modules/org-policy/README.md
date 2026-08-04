# org-policy -- Hierarchical Firewall Policy

Creates a global compute firewall policy with rules and attaches it at the
organization level. All descendant projects and VPCs inherit these rules.

## Usage

`hcl
module "org_policy" {
  source = "../modules/org-policy"

  org_id         = "123456789"
  project_prefix = "foundation"

  rules = [
    {
      priority    = 200
      action      = "allow"
      src_range   = "198.51.100.0/24"
      ports       = ["22"]
      description = "Allow SSH from corporate range"
    }
  ]
}
`

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| org_id | string | required | GCP Organization ID (numeric) |
| project_prefix | string | required | Prefix for resource naming |
| rules | list(object) | required | List of firewall policy rules |

## Outputs

| Name | Description |
|------|-------------|
| policy_id | Full resource ID of the firewall policy |
| policy_name | Short name of the firewall policy |