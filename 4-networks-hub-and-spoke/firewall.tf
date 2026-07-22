module "firewall_hub" {
  source        = "../modules/firewall"
  project_id    = local.project_ids["hub"]
  vpc_self_link = module.hub.vpc_self_link
  rules = {
    allow_ssh_iap = {
      name          = "allow-ssh-iap"
      description   = "Allow IAP SSH tunnel"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["35.235.240.0/20"]
      allow         = [{ protocol = "tcp", ports = ["22"] }]
    }
    allow_dns_inbound = {
      name          = "allow-dns-inbound"
      description   = "Allow DNS from spokes"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["10.16.0.0/16"]
      allow         = [{ protocol = "udp", ports = ["53"] }, { protocol = "tcp", ports = ["53"] }]
    }
    allow_health_checks = {
      name          = "allow-health-checks"
      description   = "Allow GCP health checks"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      allow         = [{ protocol = "tcp", ports = ["80", "443"] }]
    }
  }
}

module "firewall_spoke" {
  for_each      = var.environments
  source        = "../modules/firewall"
  project_id    = local.project_ids[each.key]
  vpc_self_link = module.spoke[each.key].vpc_self_link
  rules = {
    allow_ssh_iap = {
      name          = "allow-ssh-iap"
      description   = "Allow IAP SSH tunnel"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["35.235.240.0/20"]
      allow         = [{ protocol = "tcp", ports = ["22"] }]
    }
    allow_hub_ingress = {
      name          = "allow-hub-ingress"
      description   = "Allow traffic from hub"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["10.0.0.0/20"]
      allow         = [{ protocol = "tcp" }, { protocol = "udp" }, { protocol = "icmp" }]
    }
    allow_egress_all = {
      name               = "allow-egress-all"
      description        = "Allow all egress via NAT"
      direction          = "EGRESS"
      priority           = 1000
      destination_ranges = ["0.0.0.0/0"]
      allow              = [{ protocol = "tcp" }, { protocol = "udp" }, { protocol = "icmp" }]
    }
  }
}
