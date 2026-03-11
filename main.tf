/**
 * ## main.tf
 * This is the core wrapper around all modules provided in this terraform and serves as an example of
 * how to run this terraform to build your Azure environment.
 *
 */

/*
This is an example setup that will build a full architecture for hosting Logscale and setup a public
facing endpoint for access to Logscale / ingestion of logs. This endpoint is limited to the IP ranges
specified in your .tfvars file.
*/

# azure-core sets up the Resource Group, VNET, Subnets, Security Groups, and NAT Gateways necessary for the core buildout.
module "azure-core" {
  source                                      = "./modules/azure/core"

  subscription_id                             = var.azure_subscription_id
  environment                                 = var.azure_environment
  resource_group_region                       = var.azure_resource_group_region
  vnet_address_space                          = var.azure_vnet_address_space
  enable_azure_ddos_protection                = var.enable_azure_ddos_protection

  network_subnet_aks_system_nodes             = var.network_subnet_aks_system_nodes
  network_subnet_kafka_nodes                  = var.network_subnet_kafka_nodes
  network_subnet_aks_logscale_digest_nodes    = var.network_subnet_aks_logscale_digest_nodes
  network_subnet_ingress_nodes                = var.network_subnet_aks_ingress_nodes
  network_subnet_ingest_nodes                 = var.network_subnet_aks_ingest_nodes
  network_subnet_ui_nodes                     = var.network_subnet_aks_ui_nodes

  provision_kafka_servers                     = var.provision_kafka_servers

  logscale_lb_internal_only                   = var.logscale_lb_internal_only
  
  logscale_cluster_type                       = var.logscale_cluster_type

  tags                                        = var.tags

  name_prefix                                 = local.resource_name_prefix
}

# Keyvault is required for storing of secrets used throughout this process
module "azure-keyvault" {
  source                                      = "./modules/azure/keyvault"

  tags                                        = var.tags
  purge_protection_enabled                    = var.kv_purge_protection_enabled
  enabled_for_deployment                      = var.kv_enabled_for_deployment
  enabled_for_disk_encryption                 = var.kv_enabled_for_disk_encryption
  soft_delete_retention_days                  = var.kv_soft_delete_retention_days
  ip_ranges_allowed_kv_access                 = var.ip_ranges_allowed_kv_access

  enable_auditlogging_to_storage              = var.enable_auditlogging_to_storage
  enable_auditlogging_to_eventhub             = var.enable_auditlogging_to_eventhub
  enable_auditlogging_to_loganalytics         = var.enable_auditlogging_to_loganalytics
  enable_kv_metrics_diag_logging              = var.enable_kv_metrics_diag_logging

  diag_logging_storage_account_id             = var.diag_logging_storage_account_id
  diag_logging_eventhub_name                  = var.diag_logging_eventhub_name
  diag_logging_eventhub_authorization_rule_id = var.diag_logging_eventhub_authorization_rule_id
  diag_logging_loganalytics_id                = var.diag_logging_loganalytics_id

  name_prefix                                 = local.resource_name_prefix

  resource_group_name                         = module.azure-core.resource_group_name
  resource_group_region                       = module.azure-core.resource_group_region
}

# Create a managed azure kubernetes service (AKS) for hosting Logscale and related components
module "azure-kubernetes" {
  source                                        = "./modules/azure/aks"
  subscription_id                               = var.azure_subscription_id
  environment                                   = var.azure_environment
  admin_username                                = var.admin_username
  admin_ssh_pubkey                              = var.admin_ssh_pubkey
  private_cluster_enabled                       = var.kubernetes_private_cluster_enabled
  logscale_cluster_type                         = var.logscale_cluster_type
  tags                                          = var.tags
  azure_policy_enabled                          = var.aks_azure_policy_enabled
  cost_analysis_enabled                         = var.aks_cost_analysis_enabled
  azure_availability_zones                      = var.azure_availability_zones

  kubernetes_version                            = var.aks_kubernetes_version
  k8s_automatic_upgrade_channel                 = var.k8s_automatic_upgrade_channel
  k8s_node_os_upgrade_channel                   = var.k8s_node_os_upgrade_channel
  k8s_maintenance_window_auto_upgrade           = var.k8s_maintenance_window_auto_upgrade
  k8s_general_maintenance_windows               = var.k8s_general_maintenance_windows
  k8s_maintenance_window_node_os                = var.k8s_maintenance_window_node_os

  authorized_ip_ranges                          = var.ip_ranges_allowed_to_kubeapi != null ? concat( var.ip_ranges_allowed_to_kubeapi, ["${module.azure-core.nat_gw_public_ip}/32"] ) : null
  use_custom_certificate                        = var.use_own_certificate_for_ingress

  ip_ranges_allowed_https                       = var.ip_ranges_allowed_https

  enable_auditlogging_to_storage                = var.enable_auditlogging_to_storage
  enable_auditlogging_to_eventhub               = var.enable_auditlogging_to_eventhub
  enable_auditlogging_to_loganalytics           = var.enable_auditlogging_to_loganalytics
  enable_kv_metrics_diag_logging                = var.enable_kv_metrics_diag_logging

  diag_logging_storage_account_id               = var.diag_logging_storage_account_id
  diag_logging_eventhub_name                    = var.diag_logging_eventhub_name
  diag_logging_eventhub_authorization_rule_id   = var.diag_logging_eventhub_authorization_rule_id
  diag_logging_loganalytics_id                  = var.diag_logging_loganalytics_id

  provision_kafka_servers                       = var.provision_kafka_servers

  name_prefix                                   = local.resource_name_prefix
  azure_keyvault_secret_expiration_date         = local.kv_item_expiration_date
  
  system_node_min_count                         = local.node_group_definitions["system_node_min_node_count"]
  system_node_max_count                         = local.node_group_definitions["system_node_max_node_count"]
  system_node_desired_count                     = local.node_group_definitions["system_node_desired_node_count"]
  system_node_vmsize                            = local.node_group_definitions["system_node_instance_type"]
  system_node_os_disk_size_gb                   = local.node_group_definitions["system_node_root_disk_size"]

  logscale_node_min_count                       = local.node_group_definitions["logscale_digest_min_node_count"]
  logscale_node_max_count                       = local.node_group_definitions["logscale_digest_max_node_count"]
  logscale_node_desired_count                   = local.node_group_definitions["logscale_digest_desired_node_count"]
  logscale_node_vmsize                          = local.node_group_definitions["logscale_digest_instance_type"]
  logscale_node_os_disk_size_gb                 = local.node_group_definitions["logscale_digest_root_disk_size"]

  logscale_ingress_node_min_count               = local.node_group_definitions["logscale_ingress_min_node_count"]
  logscale_ingress_node_max_count               = local.node_group_definitions["logscale_ingress_max_node_count"]
  logscale_ingress_node_desired_count           = local.node_group_definitions["logscale_ingress_desired_node_count"]
  logscale_ingress_vmsize                       = local.node_group_definitions["logscale_ingress_instance_type"]
  logscale_ingress_os_disk_size                 = local.node_group_definitions["logscale_ingress_root_disk_size"]

  logscale_ingest_node_min_count                = local.node_group_definitions["logscale_ingest_min_node_count"]
  logscale_ingest_node_max_count                = local.node_group_definitions["logscale_ingest_max_node_count"]
  logscale_ingest_node_desired_count            = local.node_group_definitions["logscale_ingest_desired_node_count"]
  logscale_ingest_vmsize                        = local.node_group_definitions["logscale_ingest_instance_type"]
  logscale_ingest_os_disk_size                  = local.node_group_definitions["logscale_ingest_root_disk_size"]

  logscale_ui_node_min_count                    = local.node_group_definitions["logscale_ui_min_node_count"]
  logscale_ui_node_max_count                    = local.node_group_definitions["logscale_ui_max_node_count"]
  logscale_ui_node_desired_count                = local.node_group_definitions["logscale_ui_desired_node_count"]
  logscale_ui_vmsize                            = local.node_group_definitions["logscale_ui_instance_type"]
  logscale_ui_os_disk_size                      = local.node_group_definitions["logscale_ui_root_disk_size"]

  strimzi_node_instance_type                    = local.node_group_definitions["strimzi_node_instance_type"]
  strimzi_node_min_count                        = local.node_group_definitions["strimzi_node_min_node_count"]
  strimzi_node_max_count                        = local.node_group_definitions["strimzi_node_max_node_count"]
  strimzi_node_desired_count                    = local.node_group_definitions["strimzi_node_desired_node_count"]
  strimzi_node_os_disk_size_gb                  = local.node_group_definitions["strimzi_node_root_disk_size"]
  
  resource_group_name                           = module.azure-core.resource_group_name
  resource_group_region                         = module.azure-core.resource_group_region
  resource_group_id                             = module.azure-core.resource_group_id
  
  aks_system_nodes_subnet_id                    = module.azure-core.system_nodes_subnet_id
  kafka_nodes_subnet_id                         = module.azure-core.kafka_nodes_subnet_id
  logscale_digest_nodes_subnet_id               = module.azure-core.logscale_digest_nodes_subnet_id
  logscale_ingress_nodes_subnet_id              = module.azure-core.logscale_ingress_nodes_subnet_id
  logscale_ingest_nodes_subnet_id               = module.azure-core.logscale_ingest_nodes_subnet_id
  logscale_ui_nodes_subnet_id                   = module.azure-core.logscale_ui_nodes_subnet_id

  azure_keyvault_id                             = module.azure-keyvault.keyvault_id
}

# Create a storage account to use with Logscale object storage
module "logscale-storage-account" {
  source                                        = "./modules/azure/storage"
  tags                                          = var.tags 

  storage_account_replication                   = var.logscale_account_replication
  storage_account_kind                          = var.logscale_account_kind
  storage_account_tier                          = var.logscale_account_tier

  ip_ranges_allowed_storage_account_access      = var.ip_ranges_allowed_storage_account_access

  enable_auditlogging_to_storage              = var.enable_auditlogging_to_storage
  enable_auditlogging_to_eventhub             = var.enable_auditlogging_to_eventhub
  enable_auditlogging_to_loganalytics         = var.enable_auditlogging_to_loganalytics

  diag_logging_storage_account_id             = var.diag_logging_storage_account_id
  diag_logging_eventhub_name                  = var.diag_logging_eventhub_name
  diag_logging_eventhub_authorization_rule_id = var.diag_logging_eventhub_authorization_rule_id
  diag_logging_loganalytics_id                = var.diag_logging_loganalytics_id

  create_container                              = true
  azure_keyvault_secret_expiration_date         = local.kv_item_expiration_date

  name_prefix                                   = "${local.resource_name_prefix}-logscale"

  azure_keyvault_id                             = module.azure-keyvault.keyvault_id
  resource_group_region                         = module.azure-core.resource_group_region
  resource_group_name                           = module.azure-core.resource_group_name

  vnet_subnets_allowed_storage_account_access   = local.subnets_allowed_storage_account_access

}

# LogScale namespace is created by the logscale-kubernetes module
# This follows the AWS/GCP pattern where the cloud module delegates
# namespace creation to the logscale module itself

# Azure storage key secret - created after namespace but before LogScale deployment
data "azurerm_key_vault_secret" "storage_access_key" {
  name         = module.logscale-storage-account.storage_acct_access_key_kv
  key_vault_id = module.azure-keyvault.keyvault_id

  depends_on = [
    module.logscale-storage-account,
    module.azure-keyvault
  ]
}

# Azure storage key will be handled via environment variable with direct Key Vault integration
# NOTE: The azure-storage-key secret is created in storage-secret.tf via targeted deploy
# AFTER logscale-prereqs creates the namespace to avoid dependency issues

# LogScale Kubernetes deployment
module "logscale" {
  source = "../logscale-kubernetes"

  # Kubernetes cluster configuration
  k8s_config_path     = "~/.kube/config"  # Standard kubeconfig path
  k8s_cluster_context = module.azure-kubernetes.k8s_cluster_name
  k8s_namespace_prefix = var.logscale_cluster_k8s_namespace_name  # We create the namespace above

  # LogScale cluster configuration
  logscale_cluster_size = var.logscale_cluster_size
  logscale_cluster_type = var.logscale_cluster_type
  logscale_public_fqdn  = module.azure-core.ingress-pub-fqdn
  logscale_license      = var.logscale_license

  # Certificate configuration
  cert_issuer_email = var.cert_issuer_email

  # Node group definitions (using existing cluster sizing)
  node_group_definitions = local.node_group_definitions

  # Nginx ingress configuration
  nginx_ingress_sets = [
    { "name" = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal", "value" = "false" },
    { "name" = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group", "value" = module.azure-core.resource_group_name },
    { "name" = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-pip-name", "value" = module.azure-core.ingress-pub-pip-name },
    { "name" = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name", "value" = module.azure-core.ingress-pup-pip-domain-name-label },
    { "name" = "controller.service.loadBalancerIP", "value" = module.azure-core.ingress-pub-ip }
  ]

  # Azure storage environment variables - following AWS/GCP pattern
  # Note: AZURE_STORAGE_ACCOUNTKEY will be added via post-deployment step
  user_logscale_envvars = concat([
    {
      name  = "AZURE_STORAGE_ACCOUNTNAME"
      value = module.logscale-storage-account.storage_acct_name
    },
    {
      name  = "AZURE_STORAGE_BUCKET"
      value = module.logscale-storage-account.storage_acct_container_name
    },
    {
      name  = "AZURE_STORAGE_ENDPOINT_BASE"
      value = module.logscale-storage-account.storage_acct_blob_endpoint
    },
    {
      name  = "AZURE_STORAGE_OBJECT_KEY_PREFIX"
      value = local.resource_name_prefix
    },
    {
      name = "AZURE_STORAGE_ENCRYPTION_KEY"
      value = "off"
    },
    {
      name = "AZURE_STORAGE_ACCOUNTKEY"
      valueFrom = {
        secretKeyRef = {
          key = "storage-access-key"
          name = "azure-storage-key"
        }
      }
    }
  ], var.extra_user_logscale_envvars)

  # Kafka configuration
  provision_kafka_servers = var.provision_kafka_servers

  # Tags
  tags = var.tags

  # Pass through certificate configuration
  use_own_certificate_for_ingress = var.use_own_certificate_for_ingress

  # Note: Implicit dependencies through namespace reference ensure proper ordering
}


