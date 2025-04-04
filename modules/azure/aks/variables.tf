variable "subscription_id" {
  type = string
  description = "Subscription ID for your Azure resources."
}

variable "environment" {
    type = string
    description = "Azure cloud enviroment to use for your resources."
}

variable "resource_group_region" {
    type = string
    description = "The Azure cloud region for the resource group and associated resources."
}

variable "resource_group_name" {
    type = string
    description = "The Azure cloud region for the resource group and associated resources."
}

variable "logscale_digest_nodes_subnet_id" {
    description = "Subnet ID for logscale digest nodes."
}

variable "logscale_ingress_nodes_subnet_id" {
    description = "Subnet ID for ingest nodes."
}

variable "logscale_ingest_nodes_subnet_id" {
    description = "Subnet ID for ingest nodes."
}

variable "logscale_ui_nodes_subnet_id" {
    description = "Subnet ID for ingest nodes."
}

variable "aks_system_nodes_subnet_id" {
    description = "Subnet ID for AKS system nodes to live in."
}

variable "name_prefix" {
    type = string
    description = "Identifier attached to named resources to help them stand out."
}

variable "admin_username" {
    type = string
    description = "Admin username for ssh access to k8s nodes."
}

variable "admin_ssh_pubkey" {
    type = string
    description = "Public key for SSH access to the bastion host."
}

variable "logscale_cluster_type" {
  description = "Logscale cluster type"
  type        = string
}

variable "private_cluster_enabled" {
    description = "Should the kubernetes API be private only? Setting to private has implications to how to run this IaaC. Refer to documentation for more detail."
    type = bool
}

variable "tags" {
    type = map
    description = "A map of tags to apply to all created resources." 
}

variable "azure_keyvault_id" {
    type = string
    description = "Azure KeyVault id used for storing secrets related to this infrastructure"
}

variable "kafka_nodes_subnet_id" {
    type = string
    description = "Subnet ID where kafka nodes will live."
}

variable "azure_policy_enabled" {
    type = bool
    description = "Enable the Azure Policy for AKS add-on?"
}

variable "cost_analysis_enabled" {
    type = bool
    description = "Enable cost analysis for this AKS cluster?"
}

variable "sku_tier" {
    type = string
    description = "Tier for the AKS cluster, Standard or Premium"
    default = "Standard"
}

variable "authorized_ip_ranges" {
    type = list
    description = "IP Ranges allowed to access the public kubernetes API"
    default = []
}

variable "ip_ranges_allowed_https" {
    type = list
    description = "IP Ranges allowed to access the nginx-ingress loadbalancer pods"
    default = []
}

variable "resource_group_id" {
    type = string
    description = "The ID of the resource group where the kubernetes managed identity will be granted network contributor access."
}

variable "azure_keyvault_secret_expiration_date" {
    type = string
    description = "When secrets should expire."
}

variable "disk_encryption_key_expiration_date" {
    type = string
    description = "Optionally set when the disk encryption key used for AKS nodes should expire. Defaults to null on the assumption that this AKS cluster might be long-lived."
    default = null
}

/* All of these variables have to do with node pool sizing typically set in the cluster_size.tpl file*/
variable "system_node_min_count" {
    type = number
}
variable "system_node_max_count" {
    type = number
}
variable "system_node_desired_count" {
    type = number
}
variable "system_node_os_disk_size_gb" {
    type = number
}
variable "system_node_vmsize" {
    type = string
}

variable "strimzi_node_min_count" {
    type = number
}

variable "strimzi_node_max_count" {
    type = number
}

variable "strimzi_node_desired_count" {
    type = number
}

variable "strimzi_node_instance_type" {
    type = string
}

variable "strimzi_node_os_disk_size_gb" {
    type = number
}

variable "logscale_node_min_count" {
    type = number
}
variable "logscale_node_max_count" {
    type = number
}
variable "logscale_node_desired_count" {
    type = number
}
variable "logscale_node_os_disk_size_gb" {
    type = number
}
variable "logscale_node_vmsize" {
    type = string
}

variable "logscale_ingress_node_min_count" {
    type = number
}
variable "logscale_ingress_node_max_count" {
    type = number
}            
variable "logscale_ingress_node_desired_count" {
    type = number
}         
variable "logscale_ingress_vmsize" {
    type = string
}                      
variable "logscale_ingress_os_disk_size" {
    type = number
}               


variable "logscale_ingest_node_min_count" {
    type = number
}
variable "logscale_ingest_node_max_count" {
    type = number
}
variable "logscale_ingest_node_desired_count" {
    type = number
}
variable "logscale_ingest_vmsize" {
    type = string
}
variable "logscale_ingest_os_disk_size" {
    type = number
}
variable "logscale_ui_node_min_count" {
    type = number
}
variable "logscale_ui_node_max_count" {
    type = number
}
variable "logscale_ui_node_desired_count" {
    type = number
}
variable "logscale_ui_vmsize" {
    type = string
}
variable "logscale_ui_os_disk_size" {
    type = number
}

variable "enable_auditlogging_to_storage" {
    description = "Enable audit logging to a target storage account"
    default = false
    type = bool
}

variable "enable_auditlogging_to_eventhub" {
    description = "Enable audit logging to a target eventhub."
    default = false
    type = bool
}

variable "enable_auditlogging_to_loganalytics" {
    description = "Enable audit logging to a target log analytics workspace."
    default = false
    type = bool
}

variable "enable_kv_metrics_diag_logging" {
    description = "When sending diagnostic logs for the eventhub resource, we can optionally enable metrics as well."
    default = false
    type = bool
}

variable "diag_logging_storage_account_id" {
    description = "The target storage account id where audit logging will be sent."
    default = null
    type = string
}

variable "diag_logging_eventhub_name" {
    description = "The target eventhub name where audit logging will be sent. Use in conjuction with the eventhub_authorization_rule_id"
    default = null
    type = string
}

variable "diag_logging_eventhub_authorization_rule_id" {
    description = "The rule ID allowing authorization to the eventhub."
    default = null
    type = string
}

variable "diag_logging_loganalytics_id" {
    description = "The ID of the log analytics workspace to send diagnostic logging."
    default = null
    type = string
}

variable "kubernetes_diagnostic_log_categories" {
    description = "List of enabled diagnostic log categories for the kubernetes cluster."
    default = [ "kube-apiserver", "kube-controller-manager", "kube-scheduler", "kube-audit", "kube-audit-admin" ]
    type = list
}

variable "azure_availability_zones" {
    description = "The availability zones to use with your kubernetes cluster. Defaults to null making the cluster regional with no guarantee of HA in the event of zone outage."
    default = null
    type = list
}

variable "provision_kafka_servers" {
    description = "Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation."
    default = true
    type = bool
}

variable "use_custom_certificate" {
  default = false
  type = bool
  description = "Use a custom provided certificate for ingress. In this module, this setting controls creation of a NSG rule that allows for Let's Encrypt ACME challenges."
}