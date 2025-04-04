/**
 * ## Module: azure/storage
 * This module provisions a storage account and optional container designed for provisioning storage for Logscale Object storage.
 * 
 */
## Create a storage account
resource "azurerm_storage_account" "storage-account" {
  name                                  = replace("${var.name_prefix}", "-", "")
  location                              = var.resource_group_region
  resource_group_name                   = var.resource_group_name
  account_tier                          = var.storage_account_tier
  account_kind                          = var.storage_account_kind
  account_replication_type              = var.storage_account_replication
  is_hns_enabled                        = var.enable_hns
  tags                                  = var.tags
  min_tls_version                       = var.min_tls_version
  shared_access_key_enabled             = var.shared_access_key_enabled

  https_traffic_only_enabled            = true

  /* 
  This sets up IP-based access control for the storage account. By default, we should block all
  access except the subnet where the digest nodes exist. It is configurable to allow for creation of other storage
  accounts as necessary.
  */
  network_rules {
    default_action = var.storage_access_default_action
    virtual_network_subnet_ids = var.vnet_subnets_allowed_storage_account_access
    ip_rules = var.ip_ranges_allowed_storage_account_access
    bypass = var.storage_network_rules_bypass
  }
}

resource "azurerm_storage_container" "storage-account-container" {
  count                                 = var.create_container == true ? 1 : 0
  name                                  = replace("${var.name_prefix}container", "-", "")
  storage_account_id                    = azurerm_storage_account.storage-account.id 
  container_access_type                 = "private"
}

resource "azurerm_key_vault_secret" "storage-account-access-secret" {
    name                                = "${var.name_prefix}-access-key"
    key_vault_id                        = var.azure_keyvault_id
    value                               = azurerm_storage_account.storage-account.primary_access_key

    expiration_date                     = var.azure_keyvault_secret_expiration_date
    content_type                         = "storage_key"
}


resource "azurerm_monitor_diagnostic_setting" "stor-blob-diag-logging" {
    count                               = (var.enable_auditlogging_to_storage || var.enable_auditlogging_to_eventhub || var.enable_auditlogging_to_loganalytics) ? 1 : 0
    name                                = "${var.name_prefix}-stor-logging"
    target_resource_id                  = "${azurerm_storage_account.storage-account.id}/blobServices/default"

    storage_account_id                  = var.enable_auditlogging_to_storage ? var.diag_logging_storage_account_id : null
    eventhub_name                       = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_name : null
    eventhub_authorization_rule_id      = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_authorization_rule_id : null
    log_analytics_workspace_id          = var.enable_auditlogging_to_loganalytics ? var.diag_logging_loganalytics_id : null

    dynamic "enabled_log" {
        for_each = var.storage_account_blob_log_categories
        content {
            category = enabled_log.value
        }
    }
}

resource "azurerm_monitor_diagnostic_setting" "stor-file-diag-logging" {
    count                               = (var.enable_auditlogging_to_storage || var.enable_auditlogging_to_eventhub || var.enable_auditlogging_to_loganalytics) ? 1 : 0
    name                                = "${var.name_prefix}-stor-logging"
    target_resource_id                  = "${azurerm_storage_account.storage-account.id}/fileServices/default"

    storage_account_id                  = var.enable_auditlogging_to_storage ? var.diag_logging_storage_account_id : null
    eventhub_name                       = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_name : null
    eventhub_authorization_rule_id      = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_authorization_rule_id : null
    log_analytics_workspace_id          = var.enable_auditlogging_to_loganalytics ? var.diag_logging_loganalytics_id : null

    dynamic "enabled_log" {
        for_each = var.storage_account_file_log_categories
        content {
            category = enabled_log.value
        }
    }
}

resource "azurerm_monitor_diagnostic_setting" "stor-queue-diag-logging" {
    count                               = (var.enable_auditlogging_to_storage || var.enable_auditlogging_to_eventhub || var.enable_auditlogging_to_loganalytics) ? 1 : 0
    name                                = "${var.name_prefix}-stor-logging"
    target_resource_id                  = "${azurerm_storage_account.storage-account.id}/queueServices/default"

    storage_account_id                  = var.enable_auditlogging_to_storage ? var.diag_logging_storage_account_id : null
    eventhub_name                       = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_name : null
    eventhub_authorization_rule_id      = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_authorization_rule_id : null
    log_analytics_workspace_id          = var.enable_auditlogging_to_loganalytics ? var.diag_logging_loganalytics_id : null

    dynamic "enabled_log" {
        for_each = var.storage_account_queue_log_categories
        content {
            category = enabled_log.value
        }
    }
}

resource "azurerm_monitor_diagnostic_setting" "stor-table-diag-logging" {
    count                               = (var.enable_auditlogging_to_storage || var.enable_auditlogging_to_eventhub || var.enable_auditlogging_to_loganalytics) ? 1 : 0
    name                                = "${var.name_prefix}-stor-logging"
    target_resource_id                  = "${azurerm_storage_account.storage-account.id}/tableServices/default"

    storage_account_id                  = var.enable_auditlogging_to_storage ? var.diag_logging_storage_account_id : null
    eventhub_name                       = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_name : null
    eventhub_authorization_rule_id      = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_authorization_rule_id : null
    log_analytics_workspace_id          = var.enable_auditlogging_to_loganalytics ? var.diag_logging_loganalytics_id : null

    dynamic "enabled_log" {
        for_each = var.storage_account_table_log_categories
        content {
            category = enabled_log.value
        }
    }
}