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

variable "tags" {
    type = map
    description = "A map of tags to apply to all created resources." 
}

variable "purge_protection_enabled" {
    description = "Enable purge protection for KV resources"
    type = bool
    default = true
}

variable "enabled_for_deployment" {
    description = "Allow virtual machines to retrieve certificates stored as secrets in the vault"
    type = bool
    default = true
}

variable "enabled_for_disk_encryption" {
    type = bool
    default = true
    description = "Allow azure disk encryption to retrieve and unwrap keys in the vault"
}

variable "soft_delete_retention_days" {
    type = number
    default = 7
    description = "The number of days to retain items once soft-deleted. Values can be 7-90"

    validation {
        condition   = var.soft_delete_retention_days >=7 && var.soft_delete_retention_days <=90
        error_message = "soft_delete_retention_days must be between 7 and 90"
    }
}

variable "sku_name" {
    type = string
    default = "standard"

    description = "Standard or Premium SKU for the key vault."

    validation  {
        condition =  contains(["standard","premium"], var.sku_name)
        error_message = "sku_name must be standard or premium."
    }
}

variable "key_permissions" {
    description = "The keyvault will be created with an access policy that grants permission to the calling user to do most things for the purposes of this terraform run. These permissions can be adjusted as required."

    type = list
    default = [
            "Get", "List", "Update", "Delete", "Encrypt", "Decrypt", "WrapKey", 
            "UnwrapKey", "Create", "GetRotationPolicy", "SetRotationPolicy", "Recover", "Purge", "Backup"
        ]
}

variable "secret_permissions" {
    description = "The keyvault will be created with an access policy that grants permission to the calling user to do most things for the purposes of this terraform run. These permissions can be adjusted as required."
    type = list
    default = [
            "Get", "List", "Set", "Delete", "Recover"
        ]
}

variable "certificate_permissions" {
    description = "The keyvault will be created with an access policy that grants permission to the calling user to do most things for the purposes of this terraform run. These permissions can be adjusted as required."
    type = list
    default = [
            "Create", "Delete", "Get", "GetIssuers", "Import", "List", "ListIssuers", "Update"
        ]
}

variable "ip_ranges_allowed_kv_access" {
    description = "IP Ranges allowed access to keyvault outside of trusted AzureServices."
    type = list
    default = []
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
    description = "The target storage account id where audit logging for the keyvault will be sent."
    default = null
    type = string
}

variable "diag_logging_eventhub_name" {
    description = "The target eventhub name where audit logging for the keyvault will be sent. Use in conjuction with the eventhub_authorization_rule_id"
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