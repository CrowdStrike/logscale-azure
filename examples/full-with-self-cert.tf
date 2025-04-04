/**
 * ## main.tf
 * This is the core wrapper around all modules provided in this terraform and serves as an example of
 * how to run this terraform to build your Azure environment.
 *
 */
 
/*
This is an example setup that will build a full architecture but assumes a provided certificate or self-signed certificate
disabling the use of cert-manager in kubernetes.
*/

# azure-core sets up the Resource Group, VNET, Subnets, Security Groups, and NAT Gateways necessary for the core buildout.
module "azure-core" {
  source                                      = "./modules/azure/core"

  subscription_id                             = var.azure_subscription_id
  environment                                 = var.azure_environment
  resource_group_region                       = var.azure_resource_group_region
  vnet_address_space                          = var.azure_vnet_address_space
  enable_azure_ddos_protection                = var.enable_azure_ddos_protection

  bastion_network_subnet                      = var.network_subnet_bastion_nodes
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

  authorized_ip_ranges                          = concat( var.ip_ranges_allowed_to_kubeapi, ["${module.azure-core.nat_gw_public_ip}/32"] )

  ip_ranges_allowed_https                       = var.ip_ranges_allowed_https
  use_custom_certificate                        = var.use_own_certificate_for_ingress

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


# Create a self signed certificate in Azure Keyvault for use with Logscale
module "azure-selfsigned-cert" {
  source                                        = "./modules/azure/certificate"
  azure_keyvault_id                             = module.azure-keyvault.keyvault_id
  logscale_public_fqdn                          = module.azure-core.ingress-pub-fqdn
  name_prefix                                   = local.resource_name_prefix
  subject_alternative_names                     = [ module.azure-core.ingress-pub-fqdn, "othername.local", "test-name.local" ]        
}


# Install custom resource definitions in the kubernetes cluster.
# Requires kubectl to be appropriately configured on your endpoint
module "crds" {
  source                                        = "./modules/kubernetes/crds"
  humio_operator_version                        = var.humio_operator_version
  strimzi_operator_version                      = var.strimzi_operator_version
        
  k8s_config_context                            = module.azure-kubernetes.k8s_cluster_name
  k8s_config_path                               = var.k8s_config_path

}

# Install kubernetes app: Strimzi
module "kafka" {
  source                                        = "./modules/kubernetes/strimzi"

  k8s_namespace_prefix                          = var.k8s_namespace_prefix
  
  strimzi_operator_chart_version                = var.strimzi_operator_chart_version
  strimzi_operator_repo                         = var.strimzi_operator_repo

  kube_storage_class_for_kafka                  = local.node_group_definitions["kafka_broker_data_storage_class"]
  kafka_broker_pod_replica_count                = local.node_group_definitions["kafka_broker_pod_replica_count"]
  kafka_broker_resources                        = local.node_group_definitions["kafka_broker_resources"]
  kafka_broker_data_disk_size                   = local.node_group_definitions["kafka_broker_data_disk_size"]
 
  name_prefix                                   = local.resource_name_prefix

  k8s_config_context                            = module.azure-kubernetes.k8s_cluster_name
  k8s_config_path                               = var.k8s_config_path

}

/*
Install additional prerequisites: 
  * topolvm
  * cert-manager
  * nginx-ingress

And adds associated configurations. It's separated from the logscale module to make it easier to destroy/rebuild logscale by itself without
touching these resources that need changing less frequently.
*/
module "logscale-prereqs" {
  source                                        = "./modules/kubernetes/logscale-prereqs"
  # Configuration for cert-manager
  cm_repo                                       = var.cm_repo
  cm_version                                    = var.cm_version

  # Used for nginx-ingress
  k8s_namespace_prefix                          = var.k8s_namespace_prefix
  logscale_lb_internal_only                     = var.logscale_lb_internal_only
  logscale_public_fqdn                          = module.azure-core.ingress-pub-fqdn
  logscale_public_ip                            = module.azure-core.ingress-pub-ip
  azure_logscale_ingress_pip_name               = module.azure-core.ingress-pub-pip-name
  azure_logscale_ingress_domain_name_label      = module.azure-core.ingress-pup-pip-domain-name-label
  resource_group_name                           = module.azure-core.resource_group_name  
  logscale_cluster_type                         = var.logscale_cluster_type
  logscale_ingress_pod_count                    = local.node_group_definitions["logscale_ingress_desired_node_count"]
  logscale_ingress_min_pod_count                = local.node_group_definitions["logscale_ingress_min_node_count"]
  logscale_ingress_max_pod_count                = local.node_group_definitions["logscale_ingress_max_node_count"]
  logscale_ingress_resources                    = var.logscale_cluster_type == "basic" ? local.node_group_definitions["logscale_basic_ingress_resources"] : local.node_group_definitions["logscale_ingress_resources"]
  logscale_ingress_data_disk_size               = local.node_group_definitions["logscale_ingress_data_disk_size"]

  topo_lvm_chart_version                        = var.topo_lvm_chart_version
  nginx_ingress_helm_chart_version              = var.nginx_ingress_helm_chart_version
  
  # Used for let's encrypt certificate issuer
  cert_issuer_kind                              = var.cert_issuer_kind
  cert_issuer_email                             = var.cert_issuer_email
  cert_ca_server                                = var.cert_ca_server
  cert_issuer_private_key                       = var.cert_issuer_private_key
  cert_issuer_name                              = var.cert_issuer_name

  # Used everywhere for naming of resources
  name_prefix                                   = local.resource_name_prefix

  # Configure the kubernetes provider
  azure_keyvault_id                             = module.azure-keyvault.keyvault_id
  k8s_config_context                            = module.azure-kubernetes.k8s_cluster_name
  k8s_config_path                               = var.k8s_config_path

  use_custom_certificate                        = var.use_own_certificate_for_ingress
  custom_tls_certificate_keyvault_entry         = module.azure-selfsigned-cert.certificate_keyvault_name

  logscale_license                              = var.logscale_license
  password_rotation_arbitrary_value             = var.password_rotation_arbitrary_value
  azure_keyvault_secret_expiration_date         = local.kv_item_expiration_date
  azure_storage_acct_kv_name                    = module.logscale-storage-account.storage_acct_access_key_kv

}

# Install the Humio Operator and logscale cluster definitions.
module "logscale" {
  source                                        = "./modules/kubernetes/logscale"

  k8s_namespace_prefix                          = var.k8s_namespace_prefix
  k8s_config_context                            = module.azure-kubernetes.k8s_cluster_name
  k8s_config_path                               = var.k8s_config_path

  logscale_cluster_type                         = var.logscale_cluster_type

  logscale_image_version                        = var.logscale_image_version
  humio_operator_extra_values                   = var.humio_operator_extra_values
  humio_operator_repo                           = var.humio_operator_repo
  humio_operator_chart_version                  = var.humio_operator_chart_version
  humio_operator_version                        = var.humio_operator_version

  cert_issuer_name                              = var.cert_issuer_name

  user_logscale_envvars                         = var.user_logscale_envvars
  
  name_prefix                                   = local.resource_name_prefix
  target_replication_factor                     = local.node_group_definitions["logscale_target_replication_factor"]

  logscale_digest_pod_count                     = local.node_group_definitions["logscale_digest_pod_count"]
  logscale_digest_resources                     = local.node_group_definitions["logscale_digest_resources"]
  logscale_digest_data_disk_size                = local.node_group_definitions["logscale_digest_data_disk_size"]
  
  logscale_ui_resources                         = local.node_group_definitions["logscale_ui_resources"]
  logscale_ui_pod_count                         = local.node_group_definitions["logscale_ui_pod_count"]
  logscale_ui_data_disk_size                    = local.node_group_definitions["logscale_ui_data_disk_size"]

  logscale_ingest_pod_count                     = local.node_group_definitions["logscale_ingest_pod_count"]
  logscale_ingest_resources                     = local.node_group_definitions["logscale_ingest_resources"]
  logscale_ingest_data_disk_size                = local.node_group_definitions["logscale_ingest_data_disk_size"]

  azure_storage_region                          = var.azure_resource_group_region
  azure_storage_account_name                    = module.logscale-storage-account.storage_acct_name
  azure_storage_container_name                  = module.logscale-storage-account.storage_acct_container_name
  azure_storage_endpoint_base                   = module.logscale-storage-account.storage_acct_blob_endpoint

  provision_kafka_servers                       = var.provision_kafka_servers
  kafka_broker_servers                          = var.provision_kafka_servers ? module.kafka.kafka-connection-string : var.byo_kafka_connection_string

  logscale_public_fqdn                          = module.azure-core.ingress-pub-fqdn

  use_custom_certificate                        = var.use_own_certificate_for_ingress

  # In the pre-req module, we store kuberentes secrets used to configure
  # logscale which are referenced here.
  k8s_secret_static_user_logins                 = module.logscale-prereqs.k8s_secret_static_user_logins
  k8s_secret_logscale_license                   = module.logscale-prereqs.k8s_secret_logscale_license
  k8s_secret_encryption_key                     = module.logscale-prereqs.k8s_secret_encryption_key
  k8s_secret_storage_access_key                 = module.logscale-prereqs.k8s_secret_storage_access_key
  k8s_secret_user_tls_cert                      = module.logscale-prereqs.k8s_secret_user_tls_cert
}




output "resource_group_name" {
    value = try(module.azure-core.resource_group_name, null)
}

# Kubernetes information
output "k8s_cluster_name" {
    value = try(module.azure-kubernetes.k8s_cluster_name, null)
}

output "k8s_cluster_id" {
  value = try(module.azure-kubernetes.k8s_cluster_id, null)
}

output "azure_keyvault_name" {
    value = try(module.azure-keyvault.keyvault_name, null)
}

output "logscale-ingress-fqdn" {
    value = try(module.azure-core.ingress-pub-fqdn, null)
    description = "Public FQDN for access to logscale environment via Azure LB, when public access is enabled"
}

output "logscale-ingress-ip" {
    value = try(module.azure-core.ingress-pub-ip, null)
    description = "Public IP address for access to logscale environment via Azure LB, when public access is enabled"
}

output "resource_name_prefix" {
    value = local.resource_name_prefix
    description = "Prefix added to resources for unique identification"
}

output "k8s_configuration_command" {
    description = "Run this command after building the kubernetes cluster to set your local kube config"
    value = "az aks get-credentials --resource-group ${local.resource_name_prefix}-rg --name aks-${local.resource_name_prefix}"
}