[![CrowdStrike Falcon](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)](https://www.crowdstrike.com/) [![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)<br/>
# Contents
1. [Introduction](#logscale-reference-automations-for-azure-v2)
2. [Requirements and Build Information](#requirements-and-build-information)
    - [Prerequisites](#prerequisites)
    - [Azure Access Requirements](#azure-access-requirements)
    - [IP-Based Access Restrictions](#ip-based-access-restrictions)
    - [Cluster Size Configuration](#cluster-size-configuration)
3. [Build Process](#build-process)
    - [Prerequisites Setup](#prerequisites-setup)
    - [Targeted Deployment](#targeted-deployment)
    - [Post-Deployment](#post-deployment)
    - [Troubleshooting](#troubleshooting)
    - [Lessons Learned](#lessons-learned)
4. [Architecture Overview](#architecture-overview)
5. [Support](#support)
6. [References](#references)


# LogScale Reference Automations for Azure v2
This repository contains Terraform configurations to deploy an Azure-based architecture suitable for a kubernetes-based Logscale deployment. It leverages multiple Azure services including Azure Key Vault, Azure Kubernetes Service, and Azure Storage.

# Requirements and Build Information
## Prerequisites
Before starting the deployment, ensure you have the following tools and access:

- **Terraform 1.0+**: Infrastructure as Code tool for provisioning Azure resources
- **kubectl 1.28+**: kubectl is the command-line tool for interacting with the Kubernetes cluster.
- **Azure Command Line 2.68.0+**: The Azure Command Line (az cli) allows you to interact with Azure services from the command line.
- **Owner Access to Azure Subscription**: For full architecture deployment, owner access is expected to the target Azure subscription.

### Azure Access Requirements
The account running this Terraform needs to be assigned the Owner role for the target subscription due to the assignment of roles to the managed identity used by the kubernetes control plane. Role assignment for the Kubernetes cluster is as follows:

- **Reader** scoped to the Disk Encryption Set created during this process
    - Allows identity to read the disk encryption set used for node disk encryption
- **Network Contributor** scoped to the resource group created by this terraform
    - Allows identity to bind a managed load balancer to a public IP created during the Terraform run for environment access
- **Key Vault Crypto User** scoped to the Azure Key Vault created during this process
    - Allows the disk set encryption managed identity the ability to use the key vault for disk encryption

### IP-based Access Restrictions
There are five key variables that control public access to the environment and are set in your `terraform.tfvars` configuration.

**IP Range Variables:**
```
ip_ranges_allowed_to_kubeapi            = ["192.168.3.32/32", "192.168.4.1/32"]
ip_ranges_allowed_https                 = ["192.168.1.0/24"]
ip_ranges_allowed_kv_access             = ["192.168.3.32/32", "192.168.4.1/32"]
```

**Network Access Control Variables:**
```
kubernetes_private_cluster_enabled      = true   # Optional: Make k8s API private-only
logscale_lb_internal_only              = true   # Optional: Make LogScale internal-only
```

- **ip_ranges_allowed_to_kubeapi** : The Kubernetes API is publicly available by default. This variable limits access to the API and impacts the ability to run Kubernetes API commands.
- **ip_ranges_allowed_https** : The ingress endpoint for UI and Ingestion Access to Logscale is publicly available. This limits access to the given IP ranges.
- **ip_ranges_allowed_kv_access** : Access to the Azure Key Vault is limited to ranges defined here.
- **kubernetes_private_cluster_enabled** : When `true`, the Kubernetes API is only accessible from within the Azure VNet (requires VPN/ExpressRoute for external access). Overrides `ip_ranges_allowed_to_kubeapi` restrictions.
- **logscale_lb_internal_only** : When `true`, LogScale uses an internal load balancer with no public IP (requires VPN/ExpressRoute for external access). Overrides `ip_ranges_allowed_https` restrictions.

**Note:** `ip_ranges_allowed_kv_access` must be set correctly for this terraform to operate as expected. For enterprise deployments, consider enabling `kubernetes_private_cluster_enabled` and `logscale_lb_internal_only` for enhanced security.


## Cluster Size Configuration
The `cluster_size.tpl` file specifies the available parameters for different sizes of LogScale clusters. This template defines various cluster sizes (e.g., xsmall, small, medium) and their associated configurations, including node counts, instance types, disk sizes, and resource limits. The Terraform configuration uses this template to dynamically configure the LogScale deployment based on the selected cluster size.

- **File:** `cluster_size.tpl`
- **Usage:**
  The data from `cluster_size.tpl` is retrieved and rendered by the `locals.tf` file. The `locals.tf` file uses the `jsondecode` function to parse the template and select the appropriate cluster size configuration based on the `logscale_cluster_size` variable.

- **Example:**
```hcl
  # Local Variables
  locals {
    # Render a template of available cluster sizes
    cluster_size_template = jsondecode(templatefile("${path.module}/cluster_size.tpl", {}))
    cluster_size_rendered = {
      for key in keys(local.cluster_size_template) :
      key => local.cluster_size_template[key]
    }
    cluster_size_selected = local.cluster_size_rendered[var.logscale_cluster_size]
  }
```

# Build Process

Azure v2 integrates directly with logscale-kubernetes for automated deployment, consistent with AWS and GCP reference architectures.

## Prerequisites Setup

**Step 1: Repository Structure**
Ensure both repositories are cloned as siblings:
```bash
reference_architecture/
├── azure/
│   └── logscale-azure-v2/     # This repository
└── logscale-kubernetes/        # Required sibling directory
```

**Step 2: Copy example.tfvars to terraform.tfvars**
```bash
cp example.tfvars terraform.tfvars
```

**Step 3: Update `terraform.tfvars`**
Configure the following required variables for your environment:
```hcl
# Azure Configuration
azure_subscription_id           = "your-subscription-id"
azure_resource_group_region     = "eastus"  # or your preferred region
resource_name_prefix            = "mylogscl"  # max 8 characters
admin_ssh_pubkey               = "ssh-rsa AAAAB3N..."  # your SSH public key

# LogScale Configuration
logscale_cluster_type          = "basic"  # basic, ingress, dedicated-ui, or advanced
logscale_cluster_size          = "small"  # xsmall, small, medium, large, xlarge
logscale_license              = "your-logscale-license-string"
cert_issuer_email             = "admin@yourcompany.com"

# Network Access (adjust IP ranges for your organization)
ip_ranges_allowed_to_kubeapi   = ["YOUR_IP/32"]
ip_ranges_allowed_https        = ["YOUR_IP/32"]
ip_ranges_allowed_kv_access    = ["YOUR_IP/32"]
```

## Targeted Deployment

> **Pre-Deployment Checklist**
> Before starting deployment, verify:
> - [ ] Azure subscription ID is correct in `terraform.tfvars`
> - [ ] Your IP address is included in `ip_ranges_allowed_to_kubeapi` and `ip_ranges_allowed_kv_access`
> - [ ] SSH public key is valid and accessible
> - [ ] LogScale license is valid and not expired
> - [ ] Azure CLI is logged in: `az account show`
> - [ ] You have Owner permissions on the target subscription
> - [ ] Resource name prefix is unique (max 8 characters)

**Step 4: Login to Azure**
```bash
az login
```

**Step 5: Deploy Azure Infrastructure**
```bash
terraform init
terraform apply -target="module.azure-core" -target="module.azure-keyvault" -target="module.azure-kubernetes" -target="module.logscale-storage-account"
```

**Step 6: Configure kubectl for AKS**
Configure kubectl using Terraform's automated setup:
```bash
terraform apply -target="null_resource.kubeconfig_setup"

# Verify connectivity
kubectl get nodes
```

**Step 7: Deploy CRDs (Custom Resource Definitions)**
```bash
terraform apply -target="module.logscale.module.crds"
```

**Step 8: Deploy Prerequisites (creates namespaces)**
```bash
terraform apply -target="module.logscale.module.logscale-prereqs"
```

**Step 9: Deploy Kafka (optional)**
```bash
terraform apply -target="module.logscale.module.kafka"
```

**Step 10: Deploy storage secret to log namespace**
```bash
terraform apply -target="kubernetes_secret_v1.azure_storage_key"
```

**Step 11: Deploy LogScale (depends on prerequisites and storage secret)**
```bash
terraform apply -target="module.logscale.module.logscale"
```

**Step 12: Complete any remaining resources**
```bash
terraform apply
```

This targeted deployment process ensures proper dependency management:
1. Deploy Azure infrastructure (AKS cluster, storage, Key Vault)
2. Configure kubectl automatically using Terraform
3. Deploy Kubernetes Custom Resource Definitions (CRDs)
4. Deploy prerequisites (creates namespaces and cert-manager resources)
5. Deploy Kafka into the prepared namespaces
6. Deploy storage secrets after namespaces exist
7. Deploy LogScale components with all dependencies ready
8. Complete any remaining resources

**Total deployment time: ~30-45 minutes**

> **Note**: Deployment times vary based on:
> - Azure region capacity and provisioning time
> - AKS node pool creation and initialization
> - Container image pulls and startup times
> - SSL certificate generation via Let's Encrypt
> - The "advanced" cluster type creates 15 nodes across 6 specialized node pools

## Post-Deployment

After successful deployment, follow these verification steps to ensure LogScale is running properly:

### Step 1: Retrieve LogScale URL
Get the public FQDN for LogScale access:
```bash
terraform output logscale_public_fqdn
```

### Step 2: Verify Cluster Health
Check that all nodes are ready and healthy:
```bash
# Verify all nodes are Ready
kubectl get nodes

# Check node resource usage
kubectl top nodes
```

### Step 3: Verify Pod Status
Ensure all LogScale components are running:
```bash
# Check all pods in the log namespace
kubectl get pods -n log

# Verify no pods are in Error/CrashLoopBackOff state
kubectl get pods --all-namespaces | grep -E "(Error|CrashLoopBackOff|ImagePullBackOff)"

# Check LogScale-specific pods are running
kubectl get pods -n log -l app.kubernetes.io/name=humio
```

### Step 4: Verify Ingress and Load Balancer
Check that ingress is configured and has an external IP:
```bash
# Check ingress configuration
kubectl get ingress -n log

# Verify load balancer has external IP (may take 5-10 minutes)
kubectl get svc -n log-ingress -o wide

# Check certificate status
kubectl get certificate -n log
```

### Step 5: Verify LogScale Accessibility
Test LogScale web interface access:
```bash
# Get the LogScale URL
LOGSCALE_URL=$(terraform output -raw logscale_public_fqdn)
echo "LogScale URL: https://$LOGSCALE_URL"

# Test HTTP response (should return 200)
curl -I https://$LOGSCALE_URL
```

### Step 6: Initial LogScale Setup
1. **Access LogScale**: Navigate to `https://your-logscale-fqdn` in your browser
2. **Accept SSL Certificate**: If using Let's Encrypt, the certificate should be valid
3. **Initial Login**: Use the default admin credentials or create initial user account
4. **Verify License**: Check that your LogScale license is active in the UI

### Troubleshooting Common Issues

**If pods are not starting:**
```bash
# Check pod logs for specific issues
kubectl logs -n log [pod name]

# Check events for scheduling issues
kubectl get events -n log --sort-by='.lastTimestamp'
```

**If ingress has no external IP:**
```bash
# Check load balancer service status
kubectl describe svc -n log-ingress

# Verify Azure load balancer creation in Azure portal
# This can take 5-10 minutes in some regions
```

**If SSL certificate is not ready:**
```bash
# Check cert-manager logs
kubectl logs -n log-cert -l app=cert-manager

# Check certificate request status
kubectl describe certificaterequest -n log
```

**If LogScale UI is not accessible:**
1. Verify all pods are running: `kubectl get pods -n log`
2. Check service endpoints: `kubectl get endpoints -n log`
3. Verify ingress rules: `kubectl describe ingress -n log`
4. Check firewall rules allow your IP in `ip_ranges_allowed_https`

### Performance Validation
For production deployments, verify performance baselines:
```bash
# Check resource usage
kubectl top pods -n log

# Monitor cluster resource allocation
kubectl describe nodes | grep -E "(Allocated|cpu|memory)"

# Verify storage classes are available
kubectl get storageclass
```

## Troubleshooting

### Deployment Order Issues
Always deploy Azure infrastructure first, then configure kubectl, then LogScale components:
```bash
# Correct order - Infrastructure first
terraform apply -target="module.azure-core" -target="module.azure-keyvault" -target="module.azure-kubernetes" -target="module.logscale-storage-account"

# Configure kubectl automatically
terraform apply -target="null_resource.kubeconfig_setup"

# Then deploy CRDs and LogScale components step by step
terraform apply -target="module.logscale.module.crds"
# ... continue with remaining steps
```

This command will:
1. Deploy the complete Azure infrastructure (AKS cluster, storage, Key Vault)
2. Configure kubectl automatically using Terraform
3. Install all required Kubernetes Custom Resource Definitions
4. Prepare the cluster for LogScale component deployment

> **⚠️ Important**: Each `terraform apply` command will prompt for confirmation before making changes. Review the plan carefully and type `yes` when ready to proceed.

### Timeout Issues
If nginx ingress or other Helm deployments timeout:
- Monitor LoadBalancer creation: `kubectl get svc -n log-ingress -w`
- Azure LoadBalancer provisioning can take 5-10 minutes
- Retry deployment once LoadBalancer is ready


## Monitoring Best Practices
During deployment, monitor these key indicators:
```bash
# Check overall cluster status
kubectl get nodes

# Monitor LogScale pod deployment
kubectl get pods -n log -w

# Verify ingress and load balancer
kubectl get ingress -n log
kubectl get svc -n log-ingress

# Check for any pending pods
kubectl get pods --all-namespaces | grep -E "(Pending|Init|Error)"
```

### Troubleshooting Specific to Advanced Architecture
- **Node Affinity**: Pods are strictly scheduled to appropriate node pools via k8s-app labels
- **Resource Constraints**: Each node pool has specific resource limits and requests
- **Network Isolation**: Components communicate through specific subnet and security group rules
- **Storage Classes**: TopoLVM requires NVMe-capable node types for local storage

# Support
LogScale Reference Automations for Azure v2 (logscale-azure-v2) is an open source project, not a CrowdStrike product. As such, it carries no formal support, expressed or implied.

# References
- [Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/)
- [LogScale Kubernetes Documentation](https://library.humio.com/deployment/installation-k8s-ref-arch.html)
