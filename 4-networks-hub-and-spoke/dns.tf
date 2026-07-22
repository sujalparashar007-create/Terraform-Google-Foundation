resource "google_dns_policy" "hub" {
  project = local.project_ids["hub"]
  name    = "dns-policy-hub"

  enable_inbound_forwarding = true
  enable_logging            = true

  networks {
    network_url = module.hub.vpc_self_link
  }
}
