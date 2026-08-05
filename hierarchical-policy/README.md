# hierarchical-policy — Firewall Policy (Org | Folder | Project)

Creates firewall policies at any hierarchy level — configurable via `var.scope`.

## Usage

**Organization scope (hierarchical — inherited by all projects):**
```hcl
module "policy" {
  source = "../hierarchical-policy"
  scope  = "organization"
  org_id = "123456789"
  rules  = { ... }
}
```

**Folder scope (hierarchical — inherited by descendants):**
```hcl
module "policy" {
  source    = "../hierarchical-policy"
  scope     = "folder"
  folder_id = "987654321"
  rules     = { ... }
}
```

**Project scope (VPC firewall rules on a specific network):**
```hcl
module "policy" {
  source     = "../hierarchical-policy"
  scope      = "project"
  project_id = "my-proj"
  network    = "my-vpc"
  rules      = { ... }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `scope` | `string` | (required) | `organization`, `folder`, or `project` |
| `org_id` | `string` | `""` | Org ID (required for org scope) |
| `folder_id` | `string` | `""` | Folder ID (required for folder scope) |
| `project_id` | `string` | `""` | Project ID (required for project scope) |
| `network` | `string` | `""` | VPC network name (required for project scope) |
| `policy_suffix` | `string` | `"foundation"` | Short suffix for policy name |
| `rules` | `map(object({...}))` | `{}` | Firewall rules — same structure across all scopes |

## Outputs

| Name | Description |
|------|-------------|
| `policy_id` | Policy ID (null for project scope) |
| `policy_name` | Policy name (null for project scope) |
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
