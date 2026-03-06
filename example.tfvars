# ============================================================================
# LogScale Azure v2 - Terraform Configuration Example
# ============================================================================
# Copy this file to terraform.tfvars and customize for your environment

# ============================================================================
# REQUIRED CONFIGURATION
# ============================================================================

# Your Azure subscription ID (REQUIRED)
azure_subscription_id                   = "my-azure-subscription-id"

# Azure Environment - usually "public" unless using specialized clouds
# Options: public, usgovernment, german, china
azure_environment                       = "public"

# Azure Region - Choose based on data residency, latency, and compliance needs
# Supported regions: eastus, westus, centralus, eastus2, westus2, northeurope
azure_resource_group_region             = "centralus"

# Resource name prefix (max 8 characters, alphanumeric only)
# Used in naming all Azure resources. Choose carefully - changing requires redeployment
resource_name_prefix                    = "log"

# SSH public key for node access (REQUIRED for troubleshooting)
# Generate with: ssh-keygen -t rsa -b 4096 -C "logscale-azure-key"
# Provide the public key content (from .pub file)
admin_ssh_pubkey                        = "ssh-rsa ....pubkeydata.... user@host"

# Certificate issuer email (REQUIRED for Let's Encrypt certificates)
# Used for certificate generation and renewal notifications
cert_issuer_email                       = "admin@example.com"

# LogScale license (REQUIRED)
# Provide your LogScale license key
logscale_license                        = "your-logscale-license-key-here"

# ============================================================================
# CLUSTER CONFIGURATION
# ============================================================================

# Cluster type - Determines node pool configuration
# basic: System + LogScale digest nodes (development/testing)
# ingress: Adds dedicated ingress nodes (recommended)
# dedicated-ui: Adds dedicated UI nodes (production)
# advanced: Full deployment with separate ingest nodes (enterprise production)
logscale_cluster_type                   = "basic"

# Cluster size - Pre-configured sizing templates
# xsmall: Development/testing (minimal resources)
# small: Small production workloads
# medium: Standard production workloads
# large: High-volume production workloads
# xlarge: Enterprise/high-scale production
logscale_cluster_size                   = "xsmall"

# Kubernetes namespace for LogScale deployment (optional)
# Defaults to "log" if not specified
# logscale_cluster_k8s_namespace_name   = "log"

# Additional environment variables for LogScale cluster (optional)
# Supports both direct values and Kubernetes secret references
# Example:
# extra_user_logscale_envvars = [
#   {
#     name  = "MY_CUSTOM_VAR"
#     value = "custom-value"
#   },
#   {
#     name = "SECRET_VAR"
#     valueFrom = {
#       secretKeyRef = {
#         name = "my-secret"
#         key  = "secret-key"
#       }
#     }
#   }
# ]

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

# IP Ranges allowed to access the Kubernetes API (CRITICAL SECURITY SETTING)
# For production: Use your corporate network ranges only
# For development: Can include your public IP for testing
# Example: ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] for private networks
ip_ranges_allowed_to_kubeapi            = ["192.168.3.32/32", "192.168.4.1/32"]

# IP ranges allowed to access LogScale UI/Ingestion endpoint
# Set to internal networks for enterprise security
# Leave empty [] to allow access from any IP (not recommended for production)
ip_ranges_allowed_https                 = ["192.168.1.0/24"]

# IP ranges allowed to access Azure Key Vault (CRITICAL SECURITY SETTING)
# Should match or be more restrictive than kubeapi ranges
# Key Vault contains encryption keys and storage credentials
ip_ranges_allowed_kv_access             = ["192.168.3.32/32", "192.168.4.1/32"]

# Private cluster configuration (ENTERPRISE RECOMMENDED)
# true: Kubernetes API only accessible from private networks (requires VPN/ExpressRoute)
# false: API accessible from internet (restricted by ip_ranges_allowed_to_kubeapi)
kubernetes_private_cluster_enabled      = false

# Internal load balancer only (ENTERPRISE RECOMMENDED)
# true: LogScale accessible only from internal networks (requires VPN/ExpressRoute)
# false: External load balancer with public IP (restricted by ip_ranges_allowed_https)
# logscale_lb_internal_only              = false  # Uncomment and set to true for enterprise

# ============================================================================
# OPERATIONAL CONFIGURATION
# ============================================================================

# Resource tagging for cost allocation and management
# Customize based on your organization's tagging strategy
tags = {
    managedBy                           = "terraform"
    environment                         = "dev"              # dev/test/staging/prod
    resourceOwner                       = "myteam"           # Team or department
    costCenter                          = "engineering"      # For cost allocation
    project                             = "logscale"         # Project name
}

# Key Vault secret expiration (ENTERPRISE: Set to true for compliance)
# true: Secrets expire automatically, requiring periodic rotation
# false: Secrets persist indefinitely (easier management, lower security)
set_kv_expiration_dates                 = true

# ============================================================================
# HIGH AVAILABILITY CONFIGURATION
# ============================================================================

# Availability zones for multi-zone deployment (ENTERPRISE RECOMMENDED)
# Spreads node pools across zones for high availability
# Not available in all regions - check Azure documentation
azure_availability_zones                = [1,2,3]

# Storage replication for data durability
# LRS: Local redundant (single datacenter)
# ZRS: Zone redundant (multiple zones, same region)
# GRS: Geo redundant (multiple regions)
# GZRS: Geo-zone redundant (multiple zones and regions) - RECOMMENDED for enterprise
# logscale_account_replication          = "LRS"  # Uncomment and set to "GZRS" for enterprise

# ============================================================================
# KAFKA CONFIGURATION
# ============================================================================

# Provision Kafka nodes for log streaming (recommended unless using external Kafka)
# true: Deploy Strimzi Kafka nodes in the cluster
# false: Use external Kafka cluster (requires separate configuration)
provision_kafka_servers                 = true

# Bring your own Kafka connection string (only if provision_kafka_servers = false)
# Format: "broker1:9092,broker2:9092,broker3:9092"
# byo_kafka_connection_string           = ""

# ============================================================================
# MAINTENANCE WINDOWS
# ============================================================================
# Configure maintenance windows for automated updates
# Times are in UTC - adjust for your timezone and business requirements

# Kubernetes version auto-upgrade schedule
# Occurs monthly on the third Saturday - adjust for your maintenance schedule
k8s_maintenance_window_auto_upgrade = {
  frequency    = "RelativeMonthly"
  interval     = 1
  duration     = 8                    # Hours
  day_of_week  = "Saturday"           # Day of week
  week_index   = "Third"              # First/Second/Third/Fourth/Last
  utc_offset   = "+00:00"             # Adjust for your timezone
  start_time   = "01:00"              # 24-hour format
}

# Node OS patching schedule
# Occurs every 2 weeks on Sunday - adjust for your patching cycle
k8s_maintenance_window_node_os = {
  frequency    = "Weekly"
  interval     = 2                    # Every 2 weeks
  duration     = 6                    # Hours
  day_of_week  = "Sunday"
  utc_offset   = "+00:00"             # Adjust for your timezone
  start_time   = "01:00"              # 24-hour format
}

# General maintenance window - for other operations
# Define when Azure can perform other maintenance tasks
k8s_general_maintenance_windows = [
    {
        day   = "Saturday"
        hours = [2, 3, 4]             # Hours in UTC
    },
    {
        day   = "Sunday"
        hours = [2, 3, 4]             # Hours in UTC
    }
  ]

# Custom Key Vault retention (7-90 days, enterprise compliance)
# kv_soft_delete_retention_days         = 90

# ============================================================================
# VALIDATION NOTES
# ============================================================================
# Before applying:
# 1. Verify azure_subscription_id is correct
# 2. Ensure chosen region supports all required services
# 3. Check Azure quotas for VM cores and other resources
# 4. Validate IP ranges don't conflict with Azure networking
# 5. Review maintenance windows for your timezone
# 6. For enterprise: Consider enabling private cluster and internal LB
# ============================================================================
# ADVANCED KUBERNETES CONFIGURATION (Optional)
# ============================================================================

# Kubernetes namespace prefix for LogScale resources
# Multiple namespaces will be created using this prefix (e.g., log-cert-manager, log-strimzi)
# k8s_namespace_prefix                  = "log"

# Storage class for persistent volumes (TopoLVM recommended for production)
# pvc_storage_class                     = "topolvm-provisioner"

# TopoLVM configuration for dynamic volume provisioning
# use_topo_lvm                          = true
# topo_lvm_disk_pattern                 = "nvme*n*"  # Pattern to find NVMe disks
# topo_lvm_controller_replicas          = 2

# Nginx ingress controller version
# nginx_ingress_helm_chart_version      = "4.12.1"

# Deploy nginx ingress controller (set false if using external ingress)
# deploy_nginx_ingress                  = true

# ============================================================================
# OPERATOR VERSIONS (Advanced - Override defaults if needed)
# ============================================================================

# Humio Operator - manages LogScale cluster resources
# humio_operator_version                = "0.32.0"
# humio_operator_chart_version          = "0.32.0"

# Strimzi Operator - manages Kafka cluster resources
# strimzi_operator_version              = "0.47.0"
# strimzi_operator_chart_version        = "0.47.0"

# Cert-manager - manages TLS certificates
# cm_version                            = "v1.17.1"

# LogScale image version
# logscale_image_version                = "1.211.0"

# Override with custom LogScale image (requires imagePullSecrets)
# logscale_image                        = "my-registry/logscale:custom-tag"

# ============================================================================
# ADVANCED FEATURES (Optional)
# ============================================================================

# Enable PDF rendering service for scheduled reports
# enable_pdf_render_service             = false
# pdf_render_service_image              = "ghcr.io/humio/pdf-service:latest"
# pdf_render_service_node_count         = 2

# Enable scheduled report functionality
# enable_scheduled_report               = false

# Custom LogScale update strategy
# logscale_update_strategy = {
#   type                  = "RollingUpdate"
#   enableZoneAwareness   = true
#   minReadySeconds       = 120
#   maxUnavailable        = "50%"
# }

# Override node group definitions for custom cluster sizing
# node_group_definitions = {
#   logscale_digest_pod_count = 5
#   logscale_digest_resources = {
#     limits = {
#       cpu    = 4
#       memory = "16Gi"
#     }
#     requests = {
#       cpu    = 4
#       memory = "16Gi"
#     }
#   }
# }

# ============================================================================
# CERTIFICATE CONFIGURATION (Advanced)
# ============================================================================

# Bring your own certificate (disables automatic Let's Encrypt)
# use_own_certificate_for_ingress       = false

# Certificate issuer configuration (Let's Encrypt by default)
# cert_issuer_kind                      = "ClusterIssuer"
# cert_issuer_name                      = "letsencrypt-cluster-issuer"
# cert_ca_server                        = "https://acme-v02.api.letsencrypt.org/directory"
