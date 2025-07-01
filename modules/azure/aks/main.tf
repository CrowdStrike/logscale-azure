/**
 * ## Module: azure/aks
 * This module provisions managed Azure Kubernetes within the environment.
 *
 */
resource "azurerm_key_vault_key" "aks-disk-encryption-key" {
    name                                        = "diskkey-${var.name_prefix}"
    key_vault_id                                = var.azure_keyvault_id

    key_type = "RSA"
    key_size = "4096"
    key_opts = [ "wrapKey", "unwrapKey", "sign", "verify", "encrypt", "decrypt" ]

    rotation_policy {
        automatic {
            time_before_expiry = "P30D"
        }

        expire_after         = "P180D"
        notify_before_expiry = "P60D"
    }

    expiration_date                             = var.disk_encryption_key_expiration_date
} 

resource "azurerm_disk_encryption_set" "aks-disk-encryption-set" {
    name                                        = "des-${var.name_prefix}"
    location                                    = var.resource_group_region
    resource_group_name                         = var.resource_group_name

    key_vault_key_id                            = azurerm_key_vault_key.aks-disk-encryption-key.id

    identity {
        type = "SystemAssigned"
    }
}

resource "azurerm_key_vault_access_policy" "des-access-policy" {
  key_vault_id                                  = var.azure_keyvault_id
  object_id                                     = azurerm_disk_encryption_set.aks-disk-encryption-set.identity[0].principal_id
  tenant_id                                     = azurerm_disk_encryption_set.aks-disk-encryption-set.identity[0].tenant_id
  
  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey",
    "GetRotationPolicy"
  ]
}

resource "azurerm_role_assignment" "kv-des-access" {
    scope                                       = var.azure_keyvault_id
    role_definition_name                        = "Key Vault Crypto User"
    principal_id                                = azurerm_disk_encryption_set.aks-disk-encryption-set.identity[0].principal_id
}

# AKS with system nodes
resource "azurerm_kubernetes_cluster" "k8s" {
    location                                    = var.resource_group_region
    resource_group_name                         = var.resource_group_name

    kubernetes_version                          = var.kubernetes_version

    name                                        = "aks-${var.name_prefix}"
    sku_tier                                    = var.sku_tier

    # This controls the FQDN of the server. Assuming a name_prefix of asdf1234 we would end up
    # with a public fqdn of something like aks-asdf1234-#######.hcp.$region.azmk8s.io
    dns_prefix                                  = var.private_cluster_enabled == false ? "aks-${var.name_prefix}" : null
    dns_prefix_private_cluster                  = var.private_cluster_enabled == true ? "aks-${var.name_prefix}" : null
    
    # automatically upgrade the kubernetes cluster to the latest supported patch version for the major/minor release
    automatic_upgrade_channel                   = var.k8s_automatic_upgrade_channel
    node_os_upgrade_channel                     = var.k8s_node_os_upgrade_channel
    
    disk_encryption_set_id                      = azurerm_disk_encryption_set.aks-disk-encryption-set.id

    identity {
        type                                    = "SystemAssigned"
    }
    
    # Options for the user to ensure compliance with corporate policies
    azure_policy_enabled                        = var.azure_policy_enabled
    cost_analysis_enabled                       = var.cost_analysis_enabled

    # Enabling a private cluster changes control plane operations to be within the VNET but will also change how
    # access to the kube API needs to be done.
    private_cluster_enabled                     = var.private_cluster_enabled

    # Limit API access to authorized IP ranges. Public or private, api access is limited
    api_server_access_profile {
        authorized_ip_ranges                    = var.authorized_ip_ranges
    }

    # This is the "system" node pool running core components like dns, kube-proxy, etc.
    default_node_pool {
        name                                    = "lssysnode"
        temporary_name_for_rotation             = "lstmpnode"

        vnet_subnet_id                          = var.aks_system_nodes_subnet_id
        
        

        auto_scaling_enabled                    = true
        min_count                               = var.system_node_min_count
        max_count                               = var.system_node_max_count
        node_count                              = var.system_node_desired_count
        vm_size                                 = var.system_node_vmsize
        os_disk_size_gb                         = var.system_node_os_disk_size_gb

        node_public_ip_enabled                  = false

        fips_enabled                            = false
        os_sku                                  = "Ubuntu"
    
        upgrade_settings {
            max_surge                           = 50
            drain_timeout_in_minutes            = 60
            node_soak_duration_in_minutes       = 30
        }

        node_labels = {
            k8s-app                             = "support"
        }

        zones                                   = var.azure_availability_zones
    }

    network_profile {
        network_plugin                          = "azure"
        network_policy                          = "cilium"
        network_data_plane                      = "cilium"
        network_mode                            = "transparent"
        network_plugin_mode                     = "overlay"
        load_balancer_sku                       = "standard"
    }

    linux_profile {
        admin_username                          = var.admin_username
        ssh_key {
            key_data                            = var.admin_ssh_pubkey
        }
    }

    tags                                        = var.tags
    
    lifecycle {
        ignore_changes                          = [ default_node_pool[0].node_count, tags ]
    }

    maintenance_window {
        dynamic "allowed" {
            for_each = var.k8s_general_maintenance_windows != null ? var.k8s_general_maintenance_windows : [] 

            content {
                day   = allowed.value.day
                hours = allowed.value.hours
            }
        }
    }

    dynamic "maintenance_window_auto_upgrade" {
        for_each = var.k8s_maintenance_window_auto_upgrade != null ? [var.k8s_maintenance_window_auto_upgrade] : []
        
        content {
            frequency    = maintenance_window_auto_upgrade.value.frequency
            interval     = maintenance_window_auto_upgrade.value.interval
            duration     = maintenance_window_auto_upgrade.value.duration
            day_of_week  = maintenance_window_auto_upgrade.value.day_of_week
            utc_offset   = maintenance_window_auto_upgrade.value.utc_offset
            start_time   = maintenance_window_auto_upgrade.value.start_time
            
            week_index = maintenance_window_auto_upgrade.value.frequency == "RelativeMonthly" ? maintenance_window_auto_upgrade.value.week_index : null
            
        }
    }


    dynamic "maintenance_window_node_os" {
        for_each = var.k8s_maintenance_window_node_os != null ? [var.k8s_maintenance_window_node_os] : []


        content {
            frequency    = maintenance_window_node_os.value.frequency
            interval     = maintenance_window_node_os.value.interval
            duration     = maintenance_window_node_os.value.duration
            day_of_week  = maintenance_window_node_os.value.day_of_week
            utc_offset   = maintenance_window_node_os.value.utc_offset
            start_time   = maintenance_window_node_os.value.start_time

            # Only include week_index for RelativeMonthly
            week_index = maintenance_window_node_os.value.frequency == "RelativeMonthly" ? maintenance_window_node_os.value.week_index : null
            
        }
    }

    depends_on = [ azurerm_key_vault_access_policy.des-access-policy ]

}

/* 
Store k8s sensitive values in the keyvault
*/
resource "azurerm_key_vault_secret" "kube-config" {
    name                                = "${var.name_prefix}-k8s-kube-config"
    key_vault_id                        = var.azure_keyvault_id

    value                               = azurerm_kubernetes_cluster.k8s.kube_config_raw

    expiration_date                     = var.azure_keyvault_secret_expiration_date
    content_type                        = "k8s_config"
}

resource "azurerm_key_vault_secret" "client-cert" {
    name                                = "${var.name_prefix}-k8s-client-certificate"
    key_vault_id                        = var.azure_keyvault_id

    value                               = azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate
    expiration_date                     = var.azure_keyvault_secret_expiration_date
    content_type                         = "k8s_cert"
}

resource "azurerm_key_vault_secret" "client-key" {
    name                                = "${var.name_prefix}-k8s-client-key"
    key_vault_id                        = var.azure_keyvault_id

    value                               = azurerm_kubernetes_cluster.k8s.kube_config.0.client_key
    expiration_date                     = var.azure_keyvault_secret_expiration_date
    content_type                         = "k8s_cert"
}

resource "azurerm_key_vault_secret" "cluster-ca-cert" {
    name                                = "${var.name_prefix}-k8s-ca-certificate"
    key_vault_id                        = var.azure_keyvault_id

    value                               = azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate
    expiration_date                     = var.azure_keyvault_secret_expiration_date
    content_type                         = "k8s_cert"
}

/*
Create NSG for the AKS Kafka Node Subnet to limit inbound access to required access only.
*/

resource "azurerm_network_security_group" "nsg-k8s-system" {
    name                                = "nsg-${var.name_prefix}-k8s-system"
    location                            = var.resource_group_region
    resource_group_name                 = var.resource_group_name
    tags                                = var.tags

    depends_on = [ azurerm_kubernetes_cluster.k8s ]
}
 
# This allows access from the control plane of a public API server
resource "azurerm_network_security_rule" "k8s-system-inbound-rule-1a" {
    count                           = var.private_cluster_enabled == false ? 1 : 0

    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-k8s-system.name

    name                            = "Allow-Pub-AKS-API-Server"
    priority                        = 100
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "Tcp"
    source_port_range               = "*"
    destination_port_ranges          = [ "443", "10250" ]
    source_address_prefix           = "AzureCloud"
    destination_address_prefix      = "*"
}

# Allow all inbound traffic from the VNET to the kubernetes system to accommodate all services that could run here.
resource "azurerm_network_security_rule" "k8s-system-inbound-rule-1b" {
    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-k8s-system.name

    name                            = "Allow-All-VNET-Traffic"
    priority                        = 110
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "*"
    source_port_range               = "*"
    destination_port_range          = "*"
    source_address_prefix           = "VirtualNetwork"
    destination_address_prefix      = "*"
}

# Allow inbound traffic for ingress controllers when cluster type is "basic"
resource "azurerm_network_security_rule" "k8s-system-inbound-rule-1c" {
    count                           = var.logscale_cluster_type == "basic" ? 1 : 0 

    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-k8s-system.name

    name                            = "Allow-Inbound-HTTPS"
    priority                        = 150
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "*"
    source_port_range               = "*"
    destination_port_range          = "443"
    source_address_prefixes         = var.ip_ranges_allowed_https
    destination_address_prefix      = "*"
}

# Allow inbound traffic for ingress controllers when cluster type is "basic"
resource "azurerm_network_security_rule" "k8s-system-inbound-rule-1e" {
    count                           = (var.logscale_cluster_type == "basic" && var.use_custom_certificate == false) ? 1 : 0 

    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-k8s-system.name

    name                            = "Allow-Inbound-HTTP-for-cert-gen"
    priority                        = 149
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "*"
    source_port_range               = "*"
    source_address_prefix = "*"
    destination_port_ranges          = [ "80" ]
    destination_address_prefix      = "*"
}

# Allow loadbalancer health checks
resource "azurerm_network_security_rule" "k8s-system-inbound-rule-1d" {
    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-k8s-system.name

    name                            = "Allow-LB-Probes"
    priority                        = 160
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "*"
    source_port_range               = "*"
    destination_port_range          = "32595"
    source_address_prefix           = "AzureLoadBalancer"
    destination_address_prefix      = "*"
}

# By default, we're allowing all outbound traffic but this could be modified as necessary.
resource "azurerm_network_security_rule" "k8s-system-outbound-rule-1" {
    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-k8s-system.name

    name                            = "AllowAllOutbound"
    priority                        = 500
    direction                       = "Outbound"
    access                          = "Allow"
    protocol                        = "*"
    source_port_range               = "*"
    destination_port_range          = "*"
    source_address_prefix           = "*"
    destination_address_prefix      = "*"
}

resource "azurerm_subnet_network_security_group_association" "k8s-system-nsg-assoc" {
    subnet_id                           = var.aks_system_nodes_subnet_id
    network_security_group_id           = azurerm_network_security_group.nsg-k8s-system.id
}

 
# Later when we create a public IP for assignment to the ingress kubernetes pods, this will allow managed kubernetes the right permissions to handle that
resource "azurerm_role_assignment" "network-contributor" {
  scope                                         = var.resource_group_id
  role_definition_name                          = "Network Contributor"
  principal_id                                  = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
}

# Let the kubernetes principal read the disk encryption set
resource "azurerm_role_assignment" "kv-des-reader" {
    scope                                       = azurerm_disk_encryption_set.aks-disk-encryption-set.id
    role_definition_name                        = "Reader"
    principal_id                                = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
}

resource "azurerm_monitor_diagnostic_setting" "kube-diag-logging" {
    count                               = (var.enable_auditlogging_to_storage || var.enable_auditlogging_to_eventhub || var.enable_auditlogging_to_loganalytics) ? 1 : 0
    name                                = "${var.name_prefix}-kube-logging"
    target_resource_id                  = azurerm_kubernetes_cluster.k8s.id

    storage_account_id                  = var.enable_auditlogging_to_storage ? var.diag_logging_storage_account_id : null
    eventhub_name                       = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_name : null
    eventhub_authorization_rule_id      = var.enable_auditlogging_to_eventhub ? var.diag_logging_eventhub_authorization_rule_id : null
    log_analytics_workspace_id          = var.enable_auditlogging_to_loganalytics ? var.diag_logging_loganalytics_id : null

    dynamic "enabled_log" {
        for_each = var.kubernetes_diagnostic_log_categories
        content {
            category = enabled_log.value
        }
    }



    metric {
        category = "AllMetrics"
        enabled = var.enable_kv_metrics_diag_logging
    }

}