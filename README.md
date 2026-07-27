# Terraform Google Cloud Foundation

Enterprise-grade Google Cloud landing zone deployed with Terraform. Follows a **hub-and-spoke** architecture with **Shared VPC**, centralized networking, staged deployment, and **dual connectivity options** — VPC Peering and Network Connectivity Center (NCC).

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        ORGANIZATION                               │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                    0-BOOTSTRAP                              │  │
│  │   Seed Project • GCS State Bucket • Terraform SA            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────┐  ┌──────────┐  ┌────────────────┐                 │
│  │  1-ORG   │  │ 2-FOLDERS │  │ 3-HOST-PROJECTS │                │
│  │ Policies │  │ fldr-*    │  │ Hub • Dev Hosts │                │
│  └──────────┘  └──────────┘  └────────────────┘                 │
│                                    │                              │
│  ┌─────────────────────────────────┘                              │
│  │  4-NETWORKS (Hub & Spoke)                                     │
│  │                                                                 │
│  │   ┌──────────┐  ──  Connectivity ──  ┌──────────────┐        │
│  │   │ Hub VPC   │◄─── VPC Peering ───►│ Dev Spoke    │        │
│  │   │ DNS • NAT │      OR              │ VPC • NAT    │        │
│  │   │           │◄────── NCC ────────►│              │        │
│  │   └──────────┘                       └──────────────┘        │
│  │                                        │                       │
│  │  5-PROJECTS                             │                       │
│  │  ┌────────────┐                        │                       │
│  │  │ Svc Project │◄─── Shared VPC ───────┘                       │
│  │  │ VM (Test)   │                                                │
│  │  └────────────┘                                                │
│  └──────────────────────────────────────────────────────────────┘
└──────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
terraform-google-foundation/
├── 0-bootstrap/              # Seed project, state bucket, Terraform SA
├── 1-org/                    # Org-level firewall policies & IAM
├── 2-folders/                # Folder hierarchy (network, dev, nonprod, prod)
├── 3-host-projects/          # Shared VPC host projects (hub + per-environment)
├── 4-networks-hub-and-spoke/ # VPCs, subnets, connectivity, NAT, firewall, DNS
│   ├── architecture.tf        # Remote state refs & locals (connectivity flag)
│   ├── connectivity.tf        # Strategy layer: peering OR ncc module
│   ├── hub.tf                 # Hub VPC + subnet + Cloud Router
│   ├── spoke.tf               # Spoke VPCs + Shared VPC host enablement
│   ├── dns.tf                 # Cloud DNS policy (inbound forwarding)
│   ├── egress.tf              # Distributed NAT or centralized inspection
│   ├── firewall.tf            # Hub & spoke firewall rules
│   ├── outputs.tf             # VPC refs, connectivity model, NCC outputs
│   └── variables.tf           # connectivity_model, egress_model, CIDRs
├── 5-projects/                # Workloads — service projects + compute
│   └── instances/
│       ├── dev-vm/            # Validation VM in dev spoke (Shared VPC)
│       └── hub-test/          # Validation VM in hub VPC
└── modules/                   # Reusable Terraform modules
    ├── firewall/              # VPC firewall rules (dynamic maps)
    ├── folder/                # Folder factory
    ├── hub/                   # Hub VPC + subnet + Cloud Router
    ├── ncc/                   # Network Connectivity Center (hub + spokes)
    ├── org-policy/            # Hierarchical firewall policies
    ├── peering/               # VPC Network Peering (hub ↔ spoke)
    ├── project/               # GCP project factory
    ├── service-project/       # Service project + Shared VPC attachment + SA
    └── spoke/                 # Spoke VPC + subnet (VM / GKE support)
```

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Google Cloud Organization | Verified domain with org admin access |
| Billing Account | Active billing account ID |
| gcloud CLI | Installed and authenticated (`gcloud auth login`) |
| Terraform | ≥ 1.5 |
| IAM Permissions | Org-level: Project Creator, Billing User, XPN Admin |

---

## Deployment Stages

Apply in order — each stage depends on outputs from previous stages via **GCS remote state**.

### Stage 0 — Bootstrap

| Resource | Purpose |
|---|---|
| Seed Project | Hosts Terraform state bucket and service account |
| GCS State Bucket | Remote state storage (versioned, encrypted) |
| Terraform SA | CI/CD identity impersonated by all downstream stages |
| Org-level IAM | Project Creator, Billing User, XPN Admin, Security Admin |

### Stage 1 — Organization

| Resource | Purpose |
|---|---|
| Hierarchical Firewall Policy | Enterprise rules enforced at org level |
| Org IAM Bindings | Parameterized org-level role assignments |

### Stage 2 — Folders

| Folder | Purpose |
|---|---|
| `fldr-network` | Hosts networking hub project |
| `fldr-development` | Hosts dev environment projects |
| `fldr-nonproduction` | Hosts nonprod environment projects |
| `fldr-production` | Hosts prod environment projects |

### Stage 3 — Host Projects

| Project | Purpose |
|---|---|
| `foundation-hub-host-01` | Shared VPC host for hub network |
| `foundation-dev-host-01` | Shared VPC host for dev spoke |

### Stage 4 — Networks (Hub & Spoke)

| Resource | Purpose |
|---|---|
| Hub VPC (`vpc-hub`) | Central network — DNS, NAT, router |
| Dev Spoke VPC (`vpc-dev-spoke`) | Environment VPC with subnet + NAT gateway |
| Cloud Router (hub) | BGP ASN 64514 — for NAT & future interconnects |
| Cloud Router (spoke) | BGP ASN 64515 — for distributed NAT |
| Cloud NAT | Outbound internet for private VMs |
| Firewall Rules | IAP SSH, DNS, health checks, hub-spoke traffic |
| Cloud DNS Policy | Inbound DNS forwarding on hub |
| **Connectivity** | VPC Peering **or** NCC (chosen via `connectivity_model`) |

### Stage 5 — Workloads (Validation)

| Resource | Project | Purpose |
|---|---|---|
| Service Project | `foundation-dev-svc-vm-01` | Attached to dev spoke via Shared VPC |
| VM `vm-dev-test` | Service project | Debian 11, e2-micro, private IP only |
| VM `vm-hub-test` | Hub host project | Debian 11, e2-micro, private IP only |
| IAP Firewall | — | Allow 35.235.240.0/20 on tcp:22 |
| IAM | — | IAP tunnel + OS Login for operators |

---

## Quick Start

Create a `terraform.tfvars` in each stage directory, then apply in order:

```bash
# Stage 0
cd 0-bootstrap && terraform init && terraform apply

# Stage 1
cd ../1-org && terraform init && terraform apply

# Stage 2
cd ../2-folders && terraform init && terraform apply

# Stage 3
cd ../3-host-projects && terraform init && terraform apply

# Stage 4 — choose connectivity before applying (see below)
cd ../4-networks-hub-and-spoke && terraform init && terraform apply

# Stage 5
cd ../5-projects/instances/dev-vm && terraform init && terraform apply
cd ../hub-test && terraform init && terraform apply
```

---

## Connectivity Modes

The project supports **two connectivity models** for hub-to-spoke communication, controlled by a single variable.

### Configuration

In `4-networks-hub-and-spoke/terraform.tfvars`:

```hcl
connectivity_model = "peering"   # or "ncc"
egress_model       = "distributed_nat"   # or "centralized_inspection"
```

### Mode Comparison

| Feature | VPC Peering | NCC (Network Connectivity Center) |
|---|---|---|
| **Connectivity Type** | Point-to-point (1:1 peering per pair) | Hub-and-spoke via central NCC hub |
| **Scalability** | N×(N-1) peerings for N VPCs | 1 hub + N spokes |
| **Max VPCs** | 25 peerings per VPC (soft limit) | Thousands via NCC hub |
| **Route Exchange** | Subnet + custom routes (peering-specific) | Full mesh route propagation via hub |
| **Latency** | Lower (direct VPC-to-VPC) | Slightly higher (transits through NCC hub) |
| **Transitivity** | ❌ Not transitive (A↔B↔C ≠ A↔C) | ✅ Full mesh by default |
| **Cross-Project** | ✅ Supported | ✅ Supported (spoke in VPC's project) |
| **Use Case** | Simple hub-and-spoke, < 10 VPCs | Large-scale mesh, multi-cloud hybrid |
| **Module** | `modules/peering` | `modules/ncc` |

### VPC Peering (Default)

Creates bidirectional `google_compute_network_peering` resources:

```
hub-to-{env}   (hub → spoke)
spoke-to-hub   (spoke → hub)
```

### Network Connectivity Center (NCC)

Creates a global NCC hub + one spoke per VPC:

```
ncc-hub          (global hub in hub project)
ncc-spoke-hub    (connects vpc-hub)
ncc-spoke-dev    (connects vpc-dev-spoke, in dev project)
```

> **Note:** Cross-project NCC spokes require manual acceptance. Use:
> ```bash
> gcloud network-connectivity hubs accept-spoke ncc-hub \
>   --project=HUB_PROJECT \
>   --spoke=projects/SPOKE_PROJECT/locations/global/spokes/SPOKE_NAME
> ```

---

## Validation

### Validate VPC Peering

```bash
# Check peering state
gcloud compute networks peerings list \
  --network=vpc-hub --project=foundation-hub-host-01 \
  --format='table(name,state)'

# Check routes
gcloud compute routes list --project=foundation-hub-host-01 \
  --filter='network:vpc-hub' --format='table(destRange,nextHopPeering)'

# SSH into VMs and ping across VPCs
gcloud compute ssh vm-hub-test \
  --project=foundation-hub-host-01 --zone=us-east1-b --tunnel-through-iap
ping <dev-vm-internal-ip>
```

### Validate NCC

```bash
# Check hub state
gcloud network-connectivity hubs describe ncc-hub \
  --project=foundation-hub-host-01 --format='value(state)'

# Check spoke states
gcloud network-connectivity spokes list \
  --project=foundation-hub-host-01 --format='table(name,state)'
gcloud network-connectivity spokes list \
  --project=foundation-dev-host-01 --format='table(name,state)'

# Check NCC-propagated routes (should see remote subnet with nextHopHub)
gcloud compute routes list --project=foundation-hub-host-01 \
  --filter='network:vpc-hub' --format='table(destRange,nextHopHub)'

# SSH and ping test (same as peering)
gcloud compute ssh vm-hub-test \
  --project=foundation-hub-host-01 --zone=us-east1-b --tunnel-through-iap
ping <dev-vm-internal-ip>
```

### Test Egress & DNS

```bash
curl -s https://ifconfig.me    # Should return NAT IP (egress via Cloud NAT)
nslookup google.com             # Should resolve (DNS forwarding via hub)
```

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| Hub & Spoke | Centralized egress, DNS, inspection; clear security boundary |
| Shared VPC | Network admin in host project; workloads isolated in service projects |
| Staged Deployment | Independent Terraform states — no blast radius across stages |
| IAP SSH Only | No public IPs — secure access via Identity-Aware Proxy |
| OS Login | No SSH key management; IAM-controlled VM access |
| Reusable Modules | DRY — project, VPC, firewall, peering, NCC, folders all modular |
| Connectivity Strategy Pattern | Single variable toggles peering vs NCC — zero code changes |
| Remote State (GCS) | All state in versioned, encrypted bucket with per-stage prefixes |
| Service Account Impersonation | No user credentials in pipeline — Terraform SA used throughout |

---

## State Management

```
gs://foundation-tf-state-bootstrap/
├── 0-bootstrap/
├── 1-org/
├── 2-folders/
├── 3-host-projects/
├── 4-networks-hub-and-spoke/
├── 5-projects/instances/dev-vm/
└── 5-projects/instances/hub-test/
```

---

## Pros and Cons

### ✅ Pros

| Aspect | Benefit |
|---|---|
| **Modular Design** | Every component is a reusable module — hub, spoke, peering, NCC, firewall, project, folder |
| **Dual Connectivity** | One variable switches between VPC Peering and NCC — no refactoring needed |
| **Staged Deployment** | Isolated Terraform states per stage minimize blast radius and enable parallel development |
| **Enterprise Security** | IAP SSH (no public IPs), OS Login, org-level firewall policies, least-privilege IAM |
| **Shared VPC** | Centralized network administration with workload isolation in service projects |
| **GKE-Ready** | Spoke module supports VM, GKE, and mixed workloads with secondary IP ranges |
| **Scalable** | NCC mode scales to thousands of VPCs; peering mode handles dozens |
| **Remote State** | GCS backend with versioning — no local state, team collaboration ready |
| **CI/CD Ready** | Terraform SA impersonation — no user credentials in automation pipelines |

### ❌ Cons / Limitations

| Aspect | Limitation |
|---|---|
| **Sequential Apply** | Stages must be applied in order; Stage 4 depends on Stage 3 outputs |
| **NCC Cross-Project** | NCC spokes in different projects require manual acceptance (no Terraform-native auto-accept yet) |
| **No Terraform Cloud/Enterprise** | Uses GCS backend; migrating to TFC/TFE requires refactoring |
| **Region Hardcoded** | Single region (`us-east1`) — multi-region requires module extension |
| **Dev Environment Only** | Currently deploys dev spoke only; nonprod/prod need variable expansion |
| **No Terragrunt** | Manual `cd` per stage — no dependency graph orchestration |
| **Single NCC Hub** | One hub per deployment; complex multi-region NCC topologies need extension |
| **Limited Egress Models** | Distributed NAT working; centralized inspection is placeholder |

---

## Interview Questions & Answers

### Q1: Why hub-and-spoke architecture instead of full mesh?

**A:** Hub-and-spoke centralizes network controls — DNS, egress, inspection, and logging — at a single hub VPC. Spoke VPCs remain isolated from each other (unless explicitly allowed). This simplifies security management, reduces the number of connections (N spokes vs N×(N-1)/2 mesh links), and makes it easy to add spoke environments without touching existing ones. Full mesh with VPC Peering is not transitive (A→B→C ≠ A→C), which hub-and-spoke solves via the hub as a transit point.

### Q2: What is the difference between VPC Peering and Network Connectivity Center (NCC)?

**A:** VPC Peering creates direct, non-transitive 1:1 connections between VPC pairs using private Google infrastructure. NCC uses a central hub resource — VPCs attach as spokes, and the hub propagates routes in a full mesh or star topology. NCC scales to thousands of VPCs, supports transitivity, and works across on-prem (VPN/Interconnect) and cloud VPCs. Peering has lower latency (direct) but doesn't scale well beyond ~25 peerings per VPC.

### Q3: How do you manage Terraform state in this project?

**A:** State is stored in a GCS bucket (`foundation-tf-state-bootstrap`) with per-stage prefixes (e.g., `0-bootstrap/`, `4-networks-hub-and-spoke/`). This isolates state per deployment stage — a mistake in Stage 5 cannot corrupt Stage 4. The bucket is versioned and encrypted. Remote state is read cross-stage via `terraform_remote_state` data sources.

### Q4: How does Shared VPC work in this setup?

**A:** Hub and spoke projects are designated as Shared VPC **host projects**. Service projects (Stage 5) are attached as **service projects** via `google_compute_shared_vpc_service_project`. The service project's service account gets `roles/compute.networkUser` on the spoke subnet, allowing VMs in the service project to use the spoke's subnet without owning the network.

### Q5: How do you switch between VPC Peering and NCC?

**A:** Change a single variable in `terraform.tfvars`:
```hcl
connectivity_model = "peering"  # or "ncc"
```
The `connectivity.tf` strategy layer uses conditionals (`for_each` / `count`) to deploy only the chosen module. All other resources (VPCs, subnets, routers, firewall, DNS) remain unchanged regardless of which connectivity model is selected.

### Q6: Why do NCC spokes need to be in the same project as their VPC?

**A:** This is a GCP NCC requirement — `google_network_connectivity_spoke` with `linked_vpc_network` must reside in the same project as the VPC it references. For cross-project setups, each spoke is created in its VPC's project and references the NCC hub (which lives in the hub project). The hub owner must accept cross-project spokes.

### Q7: How do VMs access the internet without public IPs?

**A:** Private VMs egress through **Cloud NAT** — a managed NAT gateway configured on Cloud Routers in each spoke (distributed NAT model). Cloud NAT translates private source IPs to ephemeral external IPs from Google's pool. Inbound access is via **IAP SSH tunneling** (Identity-Aware Proxy), which requires no public IP on the VM.

### Q8: What happens if you change `connectivity_model` from `peering` to `ncc` in production?

**A:** Running `terraform apply` will:
1. **Destroy** all VPC Peering connections (network interruption during apply)
2. **Create** NCC hub + spokes (with route propagation)
3. VPCs, subnets, VMs, and all other resources remain untouched

This is a **disruptive change** — expect brief connectivity loss between VPCs. In production, you'd use a blue/green or maintenance window approach.

### Q9: How do you add a new spoke environment (e.g., production)?

**A:** Add a new entry to the `environments` variable in `4-networks-hub-and-spoke/terraform.tfvars`:
```hcl
environments = {
  dev = { ... }
  prod = {
    spoke_cidr    = "10.32.0.0/16"
    subnet_cidr   = "10.32.0.0/22"
    workload_type = "vm"
    vpc_name      = "vpc-prod-spoke"
    subnet_name   = "sb-prod-vm-us-east1"
  }
}
```
Then create a host project in Stage 3 for `prod`, run `terraform apply`, and connectivity (peering or NCC) is auto-provisioned for the new environment.

### Q10: What's the purpose of the `egress_model` variable?

**A:** It controls how outbound internet traffic is handled. Currently supports:
- `distributed_nat` — Each spoke gets its own Cloud NAT (simpler, no single point of failure)
- `centralized_inspection` — All egress routes through the hub for inspection (placeholder, requires firewall appliances)

This follows the same strategy pattern as `connectivity_model` — toggle one variable, Terraform deploys the right resources.

---

## Module Reference

| Module | Resources Created |
|---|---|
| `modules/hub` | `google_compute_network`, `google_compute_subnetwork`, `google_compute_router` |
| `modules/spoke` | `google_compute_network`, `google_compute_subnetwork` (with optional GKE secondary ranges) |
| `modules/peering` | `google_compute_network_peering` (2× — hub→spoke, spoke→hub) |
| `modules/ncc` | `google_network_connectivity_hub`, `google_network_connectivity_spoke` (N×) |
| `modules/firewall` | `google_compute_firewall` (dynamic rules via `for_each`) |
| `modules/project` | `google_project`, `google_project_service` (API enablement) |
| `modules/service-project` | `google_compute_shared_vpc_service_project`, `google_service_account`, `google_compute_subnetwork_iam_member` |
| `modules/folder` | `google_folder` |
| `modules/org-policy` | `google_compute_organization_security_policy`, `google_compute_organization_security_policy_rule` |

---

## License

MIT
