variable "resource_group_region" {
    type = string
    description = "The Azure cloud region for the resource group and associated resources."
}

variable "resource_group_name" {
    type = string
    description = "The Azure cloud region for the resource group and associated resources."
}

variable "name_prefix" {
    type = string
    description = "Identifier attached to named resources to help them stand out."
}

variable "storage_account_tier" {
    type = string
    description = "Storage account tier."
    default = "Standard"
}

variable "storage_account_kind" {
    type = string
    default = "StorageV2"
}

variable "storage_account_replication" {
    type = string
    default = "LRS"
}

variable "enable_hns" {
    type = bool
    default = true
}

variable "tags" {
    type = map
    description = "A map of tags to apply to all created resources." 
}

variable "create_container" {
    type = bool
    default = false
}

variable "azure_keyvault_id" {
    type = string
    description = "Azure KeyVault id used for storing secrets related to this infrastructure"
}

variable "vnet_subnets_allowed_storage_account_access" {
    type = list
    description = "List of subnet ids in the vnet allowed access to the storage account"
    default = []
}

variable "ip_ranges_allowed_storage_account_access" {
    type = list
    description = "IP Ranges allowed access to the storage account"
    default = []
}

variable "storage_access_default_action" {
    type = string
    description = "By default, allow or deny access to the storage account"
    default = "Deny"
}

variable "min_tls_version" {
    type = string
    default = "TLS1_2"
    description = "Minimum TLS version accepted by the storage container."
}

variable "shared_access_key_enabled" {
    type = bool
    default = true
    description = "Allow shared access keys to the storage containers. Defaults to true, as of Logscale 1.174, this method of access is required."
}

variable "azure_keyvault_secret_expiration_date" {
    type = string
    description = "When secrets should expire."
}

variable "storage_network_rules_bypass" {
    type = list
    default = ["AzureServices", "Metrics", "Logging"]
    description = "Defines traffic that can bypass the network-based restrictions applied. Can be a list containing: Metrics, Logging, and/or AzureServices. Can also be set to: None"
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

variable "storage_account_blob_log_categories" {
    description = "List of enabled diagnostic log categories for the storage account."
    default = [ "StorageRead", "StorageWrite", "StorageDelete" ]
    type = list
}

variable "storage_account_file_log_categories" {
    description = "List of enabled diagnostic log categories for the storage account."
    default = [ "StorageRead", "StorageWrite", "StorageDelete" ]
    type = list
}

variable "storage_account_queue_log_categories" {
    description = "List of enabled diagnostic log categories for the storage account."
    default = [ "StorageRead", "StorageWrite", "StorageDelete" ]
    type = list
}

variable "storage_account_table_log_categories" {
    description = "List of enabled diagnostic log categories for the storage account."
    default = [ "StorageRead", "StorageWrite", "StorageDelete" ]
    type = list
}