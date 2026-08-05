# finops-org-policy — Hierarchical Firewall Policy

Creates organization-level hierarchical firewall policies inherited by all projects, including finops VPCs. Rules are purely declarative — define them in `var.rules` without touching `main.tf`.

## Usage

```hcl
module "finops_org_policy" {
  source = "../finops-org-policy"

  org_id = "123456789"

  rules = {
    allow_finops_monitoring = {
      priority    = 100
      action      = "allow"
      src_ranges  = ["10.100.0.0/16"]
      ports       = ["9090"]
      description = "Allow FinOps monitoring collector"
    }
    deny_public_ssh = {
      priority    = 200
      action      = "deny"
      src_ranges  = ["0.0.0.0/0"]
      ports       = ["22"]
      description = "Deny public SSH to all projects"
    }
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `org_id` | `string` | (required) | GCP Organization ID (numeric) |
| `policy_suffix` | `string` | `"foundation"` | Short suffix for policy name |
| `rules` | `map(object({...}))` | `{}` | Firewall rules — priority, action, src_ranges, ports, description |

## Outputs

| Name | Description |
|------|-------------|
| `policy_id` | Full resource ID of the policy |
| `policy_name` | Short name of the policy |
