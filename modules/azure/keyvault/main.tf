/**
 * ## Module: azure/keyvault
 * This module provisions an Azure Keyvault for storing sensititve environment secrets for use across terraform modules.
 * 
 */
data "azurerm_client_config" "current" {}

## Keyvault for storing secrets that will be needed throughout this process
resource "azurerm_key_vault" "logscale-keyvault" {
    name                                    = "${var.name_prefix}-kv"
    location                                = var.resource_group_region
    resource_group_name                     = var.resource_group_name

    sku_name                                = var.sku_name
    tenant_id                               = data.azurerm_client_config.current.tenant_id

    soft_delete_retention_days              = var.soft_delete_retention_days
    enabled_for_disk_encryption             = var.enabled_for_disk_encryption
    enabled_for_deployment                  = var.enabled_for_deployment
    purge_protection_enabled                = var.purge_protection_enabled

    tags                                    = var.tags

    network_acls {
        bypass         = "AzureServices"
        default_action = "Deny"
        ip_rules       = var.ip_ranges_allowed_kv_access 
    }
}

resource "azurerm_key_vault_access_policy" "default-kv-access" {
    key_vault_id                        = azurerm_key_vault.logscale-keyvault.id
    tenant_id                           = data.azurerm_client_config.current.tenant_id
    object_id                           = data.azurerm_client_config.current.object_id

    key_permissions                     = var.key_permissions
    secret_permissions                  = var.secret_permissions
    certificate_permissions             = var.certificate_permissions

}

resource "azurerm_monitor_diagnostic_setting" "keyvault-diag-logging" {
    count                               = (var.enable_auditlogging_to_storage || var.enable_auditlogging_to_eventhub || var.enable_auditlogging_to_loganalytics) ? 1 : 0
    name                                = "${var.name_prefix}-kv-logging"
    target_resource_id                  = azurerm_key_vault.logscale-keyvault.id

    storage_account_id                  = var.enable_auditlogging_to_storage ? var.diag_logging_storage_account_id : null
    eventhub_name                       = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_name : null
    eventhub_authorization_rule_id      = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_authorization_rule_id : null
    log_analytics_workspace_id          = var.enable_auditlogging_to_loganalytics ? var.diag_logging_loganalytics_id : null

    enabled_log {
        category = "AuditEvent"
    }

    metric {
        category = "AllMetrics"
        enabled = var.enable_kv_metrics_diag_logging
    }

}