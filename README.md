[![CrowdStrike Falcon](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)]((https://www.crowdstrike.com/)) [![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)<br/>

# LogScale Reference Automations for Azure v2

This repository contains Terraform configurations to deploy an Azure-based architecture suitable for a kubernetes-based Logscale deployment. It leverages multiple Azure services including Azure Key Vault, Azure Kubernetes Service, and Azure Storage.

**🚀 Targeted Deployment** - This module integrates directly with logscale-kubernetes and requires careful dependency management for reliable deployment.

## Prerequisites

### Repository Structure
**IMPORTANT**: The `logscale-kubernetes` repository must be present as a sibling directory:
```
reference_architecture/
├── azure/
│   └── logscale-azure-v2/     # This repository
└── logscale-kubernetes/        # Required sibling directory
```

### Required Tools
- **Terraform 1.0+**, **kubectl 1.28+**, **Azure CLI 2.68.0+**, **git 2.0+**

### Azure Requirements
- Active Azure subscription with **Owner role**
- Sufficient quota for AKS clusters, storage accounts, and networking resources
- **LogScale license** (required for kubernetes deployment phase)

## Deployment Steps

**Total deployment time: ~8-12 minutes**

For detailed deployment instructions with complete configuration examples, see [docs/setup.md](docs/setup.md).

### Quick Start

### 1. Clone Repositories
Ensure both repositories are in sibling directories:
```bash
git clone <logscale-azure-v2-repo>
git clone <logscale-kubernetes-repo>
```

### 2. Configure Deployment
```bash
cd logscale-azure-v2
cp example.tfvars terraform.tfvars
# Edit terraform.tfvars with your settings (subscription ID, SSH key, LogScale license, etc.)
```

### 3. Targeted Deployment

The deployment requires careful dependency management using an 8-step targeted approach:

1. **Deploy Azure Infrastructure** - AKS cluster, Key Vault, Storage
2. **Configure kubectl** - Terraform-managed kubectl setup
3. **Deploy CRDs** - Custom Resource Definitions
4. **Deploy Prerequisites** - Namespaces and cert-manager
5. **Deploy Kafka** - Message streaming platform
6. **Deploy Storage Secret** - Azure storage integration
7. **Deploy LogScale** - Main LogScale platform
8. **Complete Deployment** - Remaining resources

**For complete step-by-step instructions, see [docs/setup.md](docs/setup.md#targeted-deployment).**

## Remote State Configuration (Recommended)

For team collaboration and production deployments, use Azure Storage as the Terraform backend:

### 1. Create Storage Account for State
```bash
# Set variables
RESOURCE_GROUP_NAME="terraform-state-rg"
STORAGE_ACCOUNT_NAME="terraformstate$(date +%s)"  # Must be globally unique
CONTAINER_NAME="tfstate"
LOCATION="eastus"  # Choose your preferred region

# Create resources
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME
```

### 2. Configure Backend
Create a `backend.tf` file in the repository root:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "your-storage-account-name"
    container_name       = "tfstate"
    key                  = "logscale-azure-v2.tfstate"
  }
}
```

## Troubleshooting

### Common Issues

**kubectl Configuration Issues**: Configure kubectl using Terraform:
```bash
terraform apply -target="null_resource.kubeconfig_setup"
kubectl get nodes
```

## Architecture

### Infrastructure Components
- **Azure Kubernetes Service (AKS)** with 5 specialized node pools
- **Azure Key Vault** for encryption keys and secrets
- **Azure Storage Account** for LogScale data persistence
- **Virtual Network** with 6 dedicated subnets
- **Public/Private Load Balancer** options for ingress

### Cluster Types
- **basic**: System + LogScale digest nodes
- **ingress**: Adds dedicated ingress nodes
- **dedicated-ui**: Adds dedicated UI nodes
- **advanced**: Full deployment with separate ingest nodes

### Cluster Sizes
Pre-configured sizing from **xsmall** (development) to **xlarge** (enterprise production)

## Network Options

### Public Access (Default)
- External load balancer for LogScale access
- Suitable for development and testing

### Private/Internal (Enterprise)
Set these in `terraform.tfvars`:
```hcl
kubernetes_private_cluster_enabled = true
logscale_lb_internal_only          = true
```
- Private AKS cluster and internal load balancer
- Requires VPN/ExpressRoute for access
- Recommended for production environments

## Documentation

- **[Azure LogScale Reference Architecture](https://library.humio.com/deployment/installation-k8s-ref-arch.html)**: Official LogScale Kubernetes documentation
- **[Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)**: Azure resource documentation

## Key Features

### Secure Azure Integration
- **Azure Key Vault** integration for secrets and encryption keys
- **Azure Storage** with secure access key management via Key Vault
- **Lifecycle management** to prevent unnecessary secret recreation

### Kubernetes-Native Deployment
- **Helm-based** LogScale deployment using official charts
- **CRD-based** configuration following Kubernetes best practices
- **Strimzi Kafka** operator for robust message streaming

### Production-Ready Architecture
- **Multi-node pool** design for workload isolation
- **Availability zone** distribution for high availability
- **Network security groups** with least-privilege access
- **Encrypted storage** for data at rest

## Support

LogScale Reference Automations for Azure v2 (logscale-azure-v2) is an open source project, not a CrowdStrike product. As such, it carries no formal support, expressed or implied.
