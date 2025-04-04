# Basic logscale group, always created.
resource "azurerm_kubernetes_cluster_node_pool" "logscale-nodes" {
    name                                = "lsdigestnode"
    temporary_name_for_rotation         = "lsdigtmpnode"
    kubernetes_cluster_id               = azurerm_kubernetes_cluster.k8s.id
    auto_scaling_enabled                = true
    vm_size                             = var.logscale_node_vmsize
    min_count                           = var.logscale_node_min_count
    max_count                           = var.logscale_node_max_count
    node_count                          = var.logscale_node_desired_count
    node_public_ip_enabled              = false
    mode                                = "User"
    os_disk_size_gb                     = var.logscale_node_os_disk_size_gb
    os_disk_type                        = "Managed"
    os_sku                              = "Ubuntu"

    vnet_subnet_id                      = var.logscale_digest_nodes_subnet_id
    
    linux_os_config {
        transparent_huge_page_enabled   = "madvise"
    }

   # kubelet_config {}
   # node_network_profile { }

    upgrade_settings {
        max_surge                       = 50
        drain_timeout_in_minutes        = 60
        node_soak_duration_in_minutes   = 30
    }

    node_labels = {
        k8s-app                         = "logscale-digest"
    }

    zones                               = var.azure_availability_zones

    tags = var.tags

    lifecycle {
        ignore_changes = [ node_count, tags, node_labels ]
    }
}


# Create NSG for the digest node subnet
resource "azurerm_network_security_group" "nsg-logscale-digest" {
    name                                = "nsg-${var.name_prefix}-logscaledigest"
    location                            = var.resource_group_region
    resource_group_name                 = var.resource_group_name
    tags                                = var.tags

    depends_on = [ azurerm_kubernetes_cluster_node_pool.logscale-nodes ]
}
 
# This allows access from the control plane of a public API server
resource "azurerm_network_security_rule" "logscaledigest-inbound-rule-1a" {
    count                           = var.private_cluster_enabled == false ? 1 : 0

    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-digest.name

    name                            = "Allow-Pub-AKS-API-Server"
    priority                        = 100
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "Tcp"
    source_port_range               = "*"
    destination_port_ranges         = [ "443", "10250" ]
    source_address_prefix           = "AzureCloud"
    destination_address_prefix      = "*"
}

# This allows cross-node communication for AKS from all VNET hosts
resource "azurerm_network_security_rule" "logscaledigest-inbound-rule-1b" {

    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-digest.name

    name                            = "Allow-AKS-Traffic"
    priority                        = 110
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "Tcp"
    source_port_range               = "*"
    destination_port_ranges         = [ "443", "10250", "30000-32767" ]
    source_address_prefix           = "VirtualNetwork"
    destination_address_prefix      = "*"
}

# Allow 8080 across the VNET for logscale access
resource "azurerm_network_security_rule" "logscaledigest-inbound-rule-2" {
    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-digest.name

    name                            = "Allow-VNET-to-Logscale"
    priority                        = 120
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "Tcp"
    source_port_range               = "*"
    destination_port_ranges         = [ "8080" ]
    source_address_prefix           = "VirtualNetwork"
    destination_address_prefix      = "*"
}

/* -- I think this rule is unnecessary. Commenting out until it can be tested/confirmed.

# Allow loadbalancer health checks
resource "azurerm_network_security_rule" "logscaledigest-inbound-rule-3" {
    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-digest.name

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
*/
# By default, we're allowing all outbound traffic but this could be modified as necessary.
resource "azurerm_network_security_rule" "logscaledigest-outbound-rule-1" {
    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-digest.name

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

resource "azurerm_subnet_network_security_group_association" "ls-digest-nsg-assoc" {
    subnet_id                           = var.logscale_digest_nodes_subnet_id
    network_security_group_id           = azurerm_network_security_group.nsg-logscale-digest.id
}
