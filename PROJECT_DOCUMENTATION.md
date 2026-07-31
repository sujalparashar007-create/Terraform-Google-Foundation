# Terraform Google Foundation — Complete Project Documentation

## 1. Overall Workflow (Deployment Order)

A **7-stage pipeline** — each stage deployed sequentially because downstream stages read outputs via **GCS remote state**:

```
STAGE 0       STAGE 1       STAGE 2        STAGE 3
BOOTSTRAP --> ORG --------> FOLDERS -----> HOST-PROJECTS
Seed Proj    Firewall       fldr-network   hub-host
TF SA        Policy         fldr-dev       dev-host
GCS Bucket   IAM
     |              |              |              |
     +--------------+--------------+------+-------+
                                          |
                              STAGE 4     |
                              NETWORKS <--+
                              Hub VPC + Spoke VPCs
                              Peering/NCC + NAT + DNS
                                    |
                         STAGE 5     |
                         PROJECTS <--+
                         dev-vm + hub-test
                                    |
                         FINOPS      |
                         DATASET <---+
                         BQ + Budgets + Alerts + CF
```

**Parallelizable pairs:** Stage 1 & 2 together. Stage 5 VMs together. FinOps runs independently.

---

## 2. Project Structure

```
terraform-google-foundation/
├── 0-bootstrap/          -> Stage 0: Seed project + TF SA + GCS bucket
├── 1-org/                -> Stage 1: Hierarchical firewall policy + IAM
├── 2-folders/            -> Stage 2: fldr-network + fldr-development
├── 3-host-projects/      -> Stage 3: hub-host + dev-host projects
├── 4-networks-hub-and-spoke/ -> Stage 4: VPCs, peering/NCC, NAT, DNS, firewalls
├── 5-projects/instances/
│   ├── dev-vm/           -> Stage 5: Service project + test VM in dev spoke
│   └── hub-test/         -> Stage 5: Test VM in hub VPC
├── test-finops-dataset/  -> FinOps: BQ dataset + views + budgets + alerts + CF
├── modules/              -> 14 reusable modules (9 infra + 5 finops)
│   ├── project/          google_project + API enablement
│   ├── folder/           google_folder + folder IAM
│   ├── hub/              VPC + subnet + Cloud Router
│   ├── spoke/            VPC + subnet + GKE secondary ranges
│   ├── peering/          Hub<->Spoke VPC peering (bidirectional)
│   ├── ncc/              NCC hub + VPC spokes (mesh)
│   ├── firewall/         VPC firewall rules factory
│   ├── service-project/  Shared VPC attachment + compute SA
│   ├── org-policy/       Hierarchical firewall policy
│   ├── finops-dataset/         BigQuery dataset + IAM
│   ├── finops-views/           6 SQL reporting views
│   ├── finops-budgets/         Billing budgets + budget view
│   ├── finops-alerts/          Pub/Sub topic + email channels
│   └── finops-budget-controls/ Scoped budgets + IAM viewers
├── .gitignore
├── README.md
└── PROJECT_DOCUMENTATION.md <- THIS FILE
```
---

## 3. File-by-File Reference

### STAGE 0 — BOOTSTRAP

| File | Why it exists | Connected to | Resources created | GCP Console validation |
|------|--------------|-------------|--------------------|----------------------|
| `0-bootstrap/main.tf` | Creates seed project, TF SA, GCS state bucket, org-level IAM. **First stage -- nothing else works without it** | Outputs consumed by ALL downstream stages | google_project (seed), google_service_account (tf-executor), google_storage_bucket (state), 8x google_organization_iam_member, 1x google_billing_account_iam_member, 9x google_project_service | **IAM & Admin > Service Accounts** -> tf-executor@foundation-bootstrap-seed. **Cloud Storage > Buckets** -> foundation-tf-state-bootstrap. **IAM > Organization > Permissions** -> verify roles |
| `0-bootstrap/variables.tf` | Declares org_id, billing, region, prefix, operators | Provides inputs to main.tf | None (declaration only) | N/A |
| `0-bootstrap/outputs.tf` | Exports terraform_sa_email, state_bucket_name, seed_project_id | Read by data.terraform_remote_state in Stages 1-5 + FinOps | None | N/A |
| `0-bootstrap/providers.tf` | Google provider using human ADC (no SA yet) | Used by all resources in main.tf | None | N/A |
| `0-bootstrap/versions.tf` | TF >=1.5, google ~>6.0, GCS backend prefix=0-bootstrap | Locked to v6.50.0 via lock.hcl | None | N/A |

### STAGE 1 — ORG POLICIES

| File | Why it exists | Connected to | Resources created | GCP Console validation |
|------|--------------|-------------|--------------------|----------------------|
| `1-org/main.tf` | Reads bootstrap state, deploys hierarchical firewall policy (via modules/org-policy), org IAM | Reads 0-bootstrap/outputs via terraform_remote_state, calls modules/org-policy | module.org_policy, google_organization_iam_member | **Network Security > Firewall Policies** -> fp-foundation-foundation |
| `1-org/variables.tf` | Declares org_id, 6 firewall CIDRs, org_iam_bindings. Contains locals { firewall_rules } with 7 hierarchical rules | Rules fed to modules/org-policy | None (declaration + locals) | N/A |
| `1-org/outputs.tf` | Exports org_policy_id | Reference only | None | N/A |

### STAGE 2 — FOLDERS

| File | Why it exists | Connected to | Resources created | GCP Console validation |
|------|--------------|-------------|--------------------|----------------------|
| `2-folders/main.tf` | Creates fldr-network + fldr-development via modules/folder | Reads 0-bootstrap outputs, calls modules/folder, consumed by Stage 3 & 5 | module.folders -> google_folder (x2) + folder IAM | **IAM & Admin > Manage Resources** -> find fldr-network, fldr-development |
| `2-folders/outputs.tf` | Exports folder_ids map (name -> numeric ID) | Consumed by 3-host-projects and 5-projects/instances/dev-vm | None | N/A |

### STAGE 3 — HOST PROJECTS

| File | Why it exists | Connected to | Resources created | GCP Console validation |
|------|--------------|-------------|--------------------|----------------------|
| `3-host-projects/main.tf` | Creates hub + dev host projects via modules/project | Reads 0-bootstrap + 2-folders outputs, calls modules/project. Output consumed by Stage 4 & 5 | module.host_project["hub"] + ["dev"] -> google_project + APIs | **Project selector** -> foundation-hub-host-01, foundation-dev-host-01 |
| `3-host-projects/outputs.tf` | Exports project_ids and project_numbers maps | Consumed by 4-networks/architecture.tf and 5-projects | None | N/A |

### STAGE 4 — NETWORKS

| File | Why it exists | Connected to | Resources created | GCP Console validation |
|------|--------------|-------------|--------------------|----------------------|
| `4-networks/architecture.tf` | Reads remote state, sets locals with feature flags (use_peering, use_ncc, use_distributed_nat) | All other files reference local.project_ids, local.use_peering, etc. | None (data + locals) | N/A |
| `4-networks/hub.tf` | Creates hub VPC + subnet + Cloud Router via modules/hub | Output vpc_self_link consumed by connectivity, dns, firewall, spoke | google_compute_network (vpc-hub), google_compute_subnetwork (sb-hub-us-east1 10.0.0.0/24), google_compute_router (cr-hub-us-east1 ASN 64514) | **VPC Network > VPC networks** -> vpc-hub. **Hybrid Connectivity > Cloud Routers** -> cr-hub-us-east1 |
| `4-networks/spoke.tf` | Creates dev spoke VPC + subnet via modules/spoke, enables Shared VPC host | Calls modules/spoke per env | google_compute_network (vpc-dev-spoke), google_compute_subnetwork (sb-dev-vm-us-east1 10.16.0.0/22), google_compute_shared_vpc_host_project | **VPC Network > VPC networks** -> vpc-dev-spoke. **VPC Network > Shared VPC** -> dev host enabled |
| `4-networks/connectivity.tf` | Strategy layer: deploys VPC Peering OR NCC based on var.connectivity_model | References module.hub + module.spoke vpc_self_links | Peering: 2x google_compute_network_peering (hub-dev). NCC: google_network_connectivity_hub + spokes | **VPC Network > VPC network peering** -> hub-to-dev. **Network Connectivity Center > Hubs** -> ncc-hub (if NCC) |
| `4-networks/dns.tf` | Cloud DNS inbound forwarding policy on hub | Attached to module.hub.vpc_self_link | google_dns_policy (dns-policy-hub) | **Network Services > Cloud DNS > DNS Server Policies** |
| `4-networks/egress.tf` | Cloud NAT per spoke (distributed NAT) | Uses module.spoke vpc_self_link | google_compute_router (cr-dev-us-east1 ASN 64515), google_compute_router_nat (nat-dev) | **VPC Network > Cloud NAT** -> nat-dev |
| `4-networks/firewall.tf` | VPC firewall rules for hub + spokes via modules/firewall | References module.hub + module.spoke vpc_self_links | Hub: 4 rules (IAP SSH, DNS, health checks, spoke ingress). Spoke: 3 rules (IAP SSH, hub ingress, egress to internet) | **VPC Network > Firewall** -> select vpc-hub / vpc-dev-spoke |
| `4-networks/variables.tf` | Declares connectivity_model (peering/ncc), egress_model (distributed_nat/centralized_inspection), CIDRs, environments map | Controls connectivity.tf, egress.tf, drives spoke.tf for_each | None | N/A |
| `4-networks/outputs.tf` | Exports VPC self-links, subnet self-links, NCC hub/spoke IDs | Consumed by 5-projects (spoke_subnets, hub_subnet_self_link) | None | N/A |
### STAGE 5 — WORKLOADS (VMs)

| File | Why it exists | Connected to | Resources created | GCP Console validation |
|------|--------------|-------------|--------------------|----------------------|
| `5-projects/instances/dev-vm/main.tf` | Service project + VM in dev spoke, IAP SSH IAM | Reads remote state from bootstrap, folders, networks. Calls modules/service-project | google_project (foundation-dev-svc-vm-01), Shared VPC attachment, compute SA, google_compute_instance (vm-dev-test e2-micro), 3x IAM (IAP, OS Login, instance admin) | **Compute Engine > VM Instances** -> vm-dev-test (10.16.x.x). **VPC Network > Shared VPC** -> service project attachment |
| `5-projects/instances/dev-vm/variables.tf` | Declares org_id, billing, zone, vm_operators | Feeds main.tf and modules/service-project | None | N/A |
| `5-projects/instances/dev-vm/outputs.tf` | vm_self_link, vm_internal_ip, service_project_id | Reference/validation | None | N/A |
| `5-projects/instances/hub-test/main.tf` | Test VM directly in hub host project for hub-side validation | Reads bootstrap, host-projects, networks remote state | google_compute_instance (vm-hub-test e2-micro), 3x IAM (IAP, OS Login, instance admin) | **Compute Engine > VM Instances** -> vm-hub-test (10.0.0.x) |
| `5-projects/instances/hub-test/variables.tf` | Declares org_id, billing, zone, vm_operators | Feeds main.tf | None | N/A |

### FINOPS (test-finops-dataset)

| File | Why it exists | Connected to | Resources created | GCP Console validation |
|------|--------------|-------------|--------------------|----------------------|
| `test-finops-dataset/main.tf` | Orchestrates all 5 FinOps modules: IAM -> dataset -> views -> alerts -> budgets -> controls -> KPI view -> Cloud Function | Calls modules/finops-*. All wired through module.finops_alerts.pubsub_topic_id | 6x IAM, 2x SA IAM, 1x billing IAM, 5x APIs, 5 modules, 1 KPI BigQuery view, 1 Cloud Functions 2nd gen, 1 GCS bucket | See module-level validation below |
| `test-finops-dataset/providers.tf` | Hardcoded to foundation-bootstrap-seed, impersonates TF SA | Used by all resources | None | N/A |
| `test-finops-dataset/versions.tf` | google ~>6.0 + archive ~>2.0 | data.archive_file uses archive provider | None | N/A |
| `function-source/main.py` | Cloud Function: Pub/Sub budget alerts -> Gmail SMTP + Teams webhook | Triggered by finops-budget-alerts Pub/Sub topic | None (app code) | **Cloud Functions** -> finops-budget-alert-processor. **Cloud Logging** -> check alerts |
| `function-source/requirements.txt` | Python deps: functions-framework, smtplib | Cloud Function build step | None | N/A |
| `function-source/test_local.py` | Local test harness | Dev only, not deployed | None | N/A |
### INFRASTRUCTURE MODULES

| Module | Why it exists | Connected to | Resources created | GCP Console validation |
|--------|--------------|-------------|--------------------|----------------------|
| `modules/project/` | Factory: creates GCP project + enables APIs. Single source of truth across all stages | Called by 3-host-projects, 5-projects/dev-vm (via service-project) | google_project + google_project_service (for_each) | **Project selector** or **IAM > Manage Resources** |
| `modules/folder/` | Factory: creates folders under org + folder IAM | Called by 2-folders | google_folder + google_folder_iam_member | **IAM > Manage Resources** |
| `modules/hub/` | Hub VPC + subnet + Cloud Router with BGP | Called by 4-networks/hub.tf | google_compute_network, google_compute_subnetwork, google_compute_router | **VPC > VPC networks**, **Hybrid Connectivity > Cloud Routers** |
| `modules/spoke/` | Spoke VPC + subnet + optional GKE secondary ranges (pod/svc) | Called by 4-networks/spoke.tf | google_compute_network, google_compute_subnetwork (+ secondary_ip_range) | **VPC > VPC networks** |
| `modules/peering/` | Bidirectional VPC peering hub<->spoke | Called when connectivity_model=peering | 2x google_compute_network_peering | **VPC > VPC network peering** |
| `modules/ncc/` | NCC hub + VPC spokes for mesh connectivity (no peering) | Called when connectivity_model=ncc | google_network_connectivity_hub + google_network_connectivity_spoke (Nx) | **Network Connectivity Center > Hubs** |
| `modules/firewall/` | Firewall rule factory via for_each on rule map | Called by 4-networks/firewall.tf for hub + spokes | google_compute_firewall (for_each) | **VPC > Firewall** |
| `modules/service-project/` | Creates service project, attaches to Shared VPC, creates compute SA, grants subnet networkUser | Called by 5-projects/dev-vm | module.project, google_compute_shared_vpc_service_project, google_service_account, google_compute_subnetwork_iam_member | **VPC > Shared VPC**, **IAM > Service Accounts** |
| `modules/org-policy/` | Hierarchical firewall policy at org level: 7 rules inherited by all projects | Called by 1-org | google_compute_firewall_policy, 7x google_compute_firewall_policy_rule, google_compute_firewall_policy_association | **Network Security > Firewall Policies** -> fp-foundation-foundation |

### FINOPS MODULES

| Module | Why it exists | Connected to | Resources created | GCP Console validation |
|--------|--------------|-------------|--------------------|----------------------|
| `modules/finops-dataset/` | BigQuery dataset for all FinOps reporting + dataset IAM | Called by test-finops-dataset (Module 0). Output consumed by views, budgets, KPI view | google_bigquery_dataset (billing_export EU) + google_bigquery_dataset_iam_binding | **BigQuery > Explorer** -> foundation-bootstrap-seed.billing_export |
| `modules/finops-views/` | 6 SQL views: daily_cost, monthly_cost_trend, cost_by_project, top_skus, discounts_and_commitments, cost_anomalies | Called by test-finops-dataset (Module 1). Reads billing export table | 6x google_bigquery_table (views) | **BigQuery > Explorer** -> billing_export > check each view |
| `modules/finops-budgets/` | Billing budgets + BigQuery view for budget targets. Wired to Pub/Sub | Called by test-finops-dataset (Module 2). Receives pubsub_topic_id from Module 3 | google_billing_budget (Monthly Overall: INR 50000) + google_bigquery_table (finops_budgets) | **Billing > Budgets** -> Monthly Overall Budget. **BigQuery** -> finops_budgets |
| `modules/finops-alerts/` | Pub/Sub topic + email notification channels for threshold alerts | Called by test-finops-dataset (Module 3). Output consumed by Module 2, 4, and Cloud Function | google_pubsub_topic (finops-budget-alerts) + google_monitoring_notification_channel (per email) | **Pub/Sub > Topics** -> finops-budget-alerts. **Monitoring > Alerting > Notification Channels** |
| `modules/finops-budget-controls/` | Per-project scoped budgets + IAM billing viewers | Called by test-finops-dataset (Module 4). Receives pubsub_topic_id + notification_channel_ids from Module 3 | google_billing_budget (Dev Projects: INR 20000 on foundation-bootstrap-seed) + google_billing_account_iam_member (viewer) | **Billing > Budgets** -> Dev Projects Budget. **Billing > Account Management > Permissions** |
---

## 4. Key Architecture Decisions

| Decision | Implementation |
|----------|---------------|
| **State management** | Single GCS bucket (foundation-tf-state-bootstrap), one prefix per stage, versioning enabled |
| **Authentication** | Stage 0 uses human ADC. Stages 1-5 impersonate tf-executor@foundation-bootstrap-seed |
| **Connectivity** | Toggle connectivity_model = "peering" or "ncc" in 4-networks/terraform.tfvars |
| **Egress** | Toggle egress_model = "distributed_nat" or "centralized_inspection" |
| **Project naming** | ${var.project_prefix}-{purpose}-{env}-{NN} e.g. foundation-hub-host-01 |
| **Shared VPC** | Hub + Dev are host projects. Service projects attach to respective host |
| **FinOps alerting** | Budget threshold -> Pub/Sub -> Cloud Function -> Gmail + Microsoft Teams |

---

## 5. Deployed Resources Summary

| Category | Count | Examples |
|----------|-------|----------|
| GCP Projects | 5 | foundation-bootstrap-seed, foundation-hub-host-01, foundation-dev-host-01, foundation-dev-svc-vm-01 |
| Folders | 2 | fldr-network, fldr-development |
| VPC Networks | 3 | vpc-hub, vpc-dev-spoke |
| Subnets | 2 | sb-hub-us-east1 (10.0.0.0/24), sb-dev-vm-us-east1 (10.16.0.0/22) |
| Cloud Routers | 2 | cr-hub-us-east1 (ASN 64514), cr-dev-us-east1 (ASN 64515) |
| Cloud NAT | 1 | nat-dev |
| VPC Peerings | 2 | hub-to-dev, spoke-to-hub |
| Compute VMs | 2 | vm-hub-test, vm-dev-test (both e2-micro) |
| Service Accounts | 3 | tf-executor (seed), svc-vm-default (dev-svc) |
| Firewall Rules | 14 | 7 org-level + 4 hub + 3 spoke |
| DNS Policies | 1 | dns-policy-hub |
| GCS Buckets | 2 | foundation-tf-state-bootstrap, foundation-finops-function-source |
| BigQuery Dataset | 1 | billing_export (EU) |
| BigQuery Views | 7 | daily_cost, monthly_cost_trend, cost_by_project, top_skus, discounts_and_commitments, cost_anomalies, monthly_kpi_summary, finops_budgets |
| Billing Budgets | 2 | Monthly Overall (INR 50000), Dev Projects (INR 20000) |
| Pub/Sub Topics | 1 | finops-budget-alerts |
| Cloud Functions | 1 | finops-budget-alert-processor (2nd gen) |

---

**Generated:** July 2026 | **Terraform:** 1.15.5 | **Google Provider:** 6.50.0