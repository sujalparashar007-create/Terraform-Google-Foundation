# Terraform Google Cloud Foundation

Enterprise-grade Google Cloud landing zone deployed with Terraform. Follows a **hub-and-spoke** architecture with **Shared VPC**, centralized networking, and staged deployment.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   ORGANIZATION                       │
│  ┌───────────────────────────────────────────────┐  │
│  │              0-BOOTSTRAP                       │  │
│  │  Seed Project • GCS State Bucket • Terraform SA │  │
│  └───────────────────────────────────────────────┘  │
│                                                      │
│  ┌────────────┐  ┌──────────┐  ┌────────────────┐  │
│  │   1-ORG     │  │ 2-FOLDERS │  │ 3-HOST-PROJECTS │  │
│  │ Org Policies│  │ fldr-*    │  │ Hub • Dev Hosts │  │
│  └────────────┘  └──────────┘  └────────────────┘  │
│                                      │               │
│  ┌───────────────────────────────────┘               │
│  │  4-NETWORKS (Hub & Spoke)                         │
│  │  ┌──────────┐     ┌──────────────┐               │
│  │  │ Hub VPC   │◄───►│ Dev Spoke VPC│               │
│  │  │ DNS • NAT │     │ Subnet • NAT │               │
│  │  └──────────┘     └──────────────┘               │
│  │                          │                        │
│  │  5-PROJECTS               │                        │
│  │  ┌──────────────┐        │                        │
│  │  │ Service Proj  │◄──────┘                        │
│  │  │ VM (Test)    │  Shared VPC                     │
│  │  └──────────────┘                                  │
│  └───────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────┘
```

## Project Structure

```
terraform-google-foundation/
├── 0-bootstrap/          # Seed project, state bucket, Terraform SA
├── 1-org/                # Org-level firewall policies & IAM
├── 2-folders/            # Folder hierarchy (network, dev, nonprod, prod)
├── 3-host-projects/      # Shared VPC host projects (hub + per-environment)
├── 4-networks-hub-and-spoke/  # VPCs, subnets, peering, NAT, firewall, DNS
├── 5-projects/           # Workloads — service projects + compute
│   └── instances/dev-vm/       # Validation VM (IAP SSH + NAT + DNS)
└── modules/              # Reusable Terraform modules
    ├── firewall/         # VPC firewall rules
    ├── folder/           # Folder factory
    ├── hub/              # Hub VPC + subnet + Cloud Router
    ├── org-policy/       # Hierarchical firewall policies
    ├── peering/          # VPC peering
    ├── project/          # GCP project factory
    ├── service-project/  # Service project + Shared VPC attachment
    └── spoke/            # Spoke VPC + subnet
```

## Deployment Stages

Apply in order — each stage depends on outputs from previous stages.

### Stage 0 — Bootstrap
| Resource | Purpose |
|----------|---------|
| Seed Project | Hosts Terraform state bucket and service account |
| GCS State Bucket | Remote state storage (versioned, encrypted) |
| Terraform SA | CI/CD identity used by all downstream stages |
| Org-level IAM | Project Creator, Billing User, XPN Admin, Security Admin |

### Stage 1 — Organization
| Resource | Purpose |
|----------|---------|
| Hierarchical Firewall Policy | 7 enterprise rules at org level (via modules/org-policy) |
| Org IAM Bindings | Parameterized org-level role assignments |

### Stage 2 — Folders
| Resource | Purpose |
|----------|---------|
| `fldr-network` | Hosts networking hub project |
| `fldr-development` | Hosts dev environment projects |
| `fldr-nonproduction` | Hosts nonprod environment projects |
| `fldr-production` | Hosts prod environment projects |

### Stage 3 — Host Projects
| Resource | Purpose |
|----------|---------|
| `prj-hub-host` | Shared VPC host for hub network |
| `prj-dev-host` | Shared VPC host for dev spoke |

### Stage 4 — Networks (Hub & Spoke)
| Resource | Purpose |
|----------|---------|
| Hub VPC | Central network with DNS forwarding |
| Dev Spoke VPC | Environment VPC with subnet + NAT gateway |
| VPC Peering | Hub ↔ dev spoke with custom route exchange |
| Cloud NAT | Outbound internet for private VMs |
| Cloud Router | BGP for NAT and future interconnects |
| Firewall Rules | IAP SSH, DNS, health checks, hub-spoke traffic |
| Cloud DNS Policy | Inbound DNS forwarding on hub |

### Stage 5 — Workloads (Validation)
| Resource | Purpose |
|----------|---------|
| Service Project | Attached to dev spoke via Shared VPC |
| Compute VM (`vm-dev-test`) | Debian 12, e2-micro, private IP only |
| IAP Firewall | Allow 35.235.240.0/20 on tcp:22 |
| IAM | IAP tunnel + OS Admin Login for SSH user |

## Prerequisites

- Google Cloud organization with verified domain
- Billing account
- `gcloud` CLI installed and authenticated
- Terraform ≥ 1.5

## Quick Start

```powershell
# Apply each stage in order:
cd 0-bootstrap && terraform init && terraform apply
cd ../1-org && terraform init && terraform apply
cd ../2-folders && terraform init && terraform apply
cd ../3-host-projects && terraform init && terraform apply
cd ../4-networks-hub-and-spoke && terraform init && terraform apply
cd ../5-projects/instances/dev-vm && terraform init && terraform apply
```

> Create a `terraform.tfvars` file in each stage directory with required variables.

## Validation

SSH into the test VM via IAP (no public IP required):

```powershell
gcloud compute ssh vm-dev-test --zone=us-east1-b --tunnel-through-iap --project=foundation-dev-svc-vm
```

Inside the VM, verify end-to-end networking:

```bash
curl -s https://ifconfig.me    # Should return a NAT IP (egress via Cloud NAT)
nslookup google.com             # Should resolve (DNS forwarding via hub)
```

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Hub & Spoke | Centralized egress, DNS, and future inspection |
| Shared VPC | Network admin in host project; workloads isolated in service projects |
| Staged deployment | Independent Terraform states per stage — no blast radius |
| IAP SSH only | No public IPs on VMs — secure access via Identity-Aware Proxy |
| OS Login | No SSH keys to manage; IAM-controlled VM access |
| Reusable modules | DRY pattern for project, VPC, firewall, peering, folders |

## State Management

All state stored in a single GCS bucket with per-stage prefixes:

```
gs://foundation-tf-state-bootstrap/
├── 0-bootstrap/
├── 1-org/
├── 2-folders/
├── 3-host-projects/
├── 4-networks-hub-and-spoke/
└── 5-projects/instances/dev-vm/
```

