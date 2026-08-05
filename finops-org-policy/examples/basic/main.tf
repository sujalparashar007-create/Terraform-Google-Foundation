# Example: finops-org-policy basic usage
# Creates an org-level hierarchical firewall policy.
# Rules match 1-org stage — same security baseline.
# Run: terraform init && terraform validate

module "finops_org_policy" {
  source = "../../"

  org_id = "123456789"

  rules = {
    corp_ssh = {
      priority    = 200
      action      = "allow"
      src_ranges  = ["198.51.100.0/24"]
      ports       = ["22"]
      description = "Allow enterprise SSH from corporate range"
    }
    vpn_ssh = {
      priority    = 300
      action      = "allow"
      src_ranges  = ["198.51.101.0/24"]
      ports       = ["22"]
      description = "Allow enterprise SSH from VPN range"
    }
    bastion_ssh = {
      priority    = 400
      action      = "allow"
      src_ranges  = ["10.10.10.0/24"]
      ports       = ["22"]
      description = "Allow enterprise SSH from bastion range"
    }
    vuln_scanner = {
      priority    = 500
      action      = "allow"
      src_ranges  = ["10.20.0.0/24"]
      ports       = ["443", "9100"]
      description = "Allow vulnerability scanner"
    }
    monitoring = {
      priority    = 600
      action      = "allow"
      src_ranges  = ["10.30.0.0/24"]
      ports       = ["9090"]
      description = "Allow monitoring collector"
    }
    backup = {
      priority    = 700
      action      = "allow"
      src_ranges  = ["10.40.0.0/24"]
      ports       = ["8443"]
      description = "Allow backup service"
    }
  }
}
