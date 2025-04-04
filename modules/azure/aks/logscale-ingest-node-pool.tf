resource "azurerm_kubernetes_cluster_node_pool" "logscale-ingest-nodes" {
    count                               = contains(["advanced"], var.logscale_cluster_type) ? 1 : 0

    name                                = "lsingestnode"
    temporary_name_for_rotation         = "lsintmpnode"
    kubernetes_cluster_id               = azurerm_kubernetes_cluster.k8s.id
    auto_scaling_enabled                = true
    vm_size                             = var.logscale_ingest_vmsize
    min_count                           = var.logscale_ingest_node_min_count
    max_count                           = var.logscale_ingest_node_max_count
    node_count                          = var.logscale_ingest_node_desired_count
    node_public_ip_enabled              = false
    mode                                = "User"
    os_disk_size_gb                     = var.logscale_ingest_os_disk_size
    os_disk_type                        = "Managed"
    os_sku                              = "Ubuntu"

    vnet_subnet_id                      = var.logscale_ingest_nodes_subnet_id
    
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
        k8s-app                         = "logscale-ingest"
    }

    zones                               = var.azure_availability_zones

    tags = var.tags

    lifecycle {
        ignore_changes = [ node_count, tags, node_labels ]
    }
}

# Create NSG for ingest subnet
resource "azurerm_network_security_group" "nsg-logscale-ingest" {
    count                               = contains(["advanced"], var.logscale_cluster_type) ? 1 : 0
    
    name                                = "nsg-${var.name_prefix}-lsingest"
    location                            = var.resource_group_region
    resource_group_name                 = var.resource_group_name
    tags                                = var.tags

    depends_on = [ azurerm_kubernetes_cluster_node_pool.logscale-ingest-nodes ]
}
 
# This allows access from the control plane of a public API server when the API is not private
resource "azurerm_network_security_rule" "lsingest-inbound-rule-1a" {
    count                           = (contains(["advanced"], var.logscale_cluster_type) && (var.private_cluster_enabled == false)) ? 1 : 0

    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-ingest[0].name

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

# This allows cross-node communication for AKS from all VNET hosts which should include
resource "azurerm_network_security_rule" "lsingest-inbound-rule-1b" {
    count                           = contains(["advanced"], var.logscale_cluster_type) ? 1 : 0

    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-ingest[0].name

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

resource "azurerm_network_security_rule" "lsingest-inbound-rule-2" {
    count                           = contains(["advanced"], var.logscale_cluster_type) ? 1 : 0 
    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-ingest[0].name

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

# By default, we're allowing all outbound traffic but this could be modified as necessary.
resource "azurerm_network_security_rule" "lsingest-outbound-rule-1" {
    count                           = contains(["advanced"], var.logscale_cluster_type) ? 1 : 0 
    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-ingest[0].name

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

resource "azurerm_subnet_network_security_group_association" "ls-ingest-nsg-assoc" {
    count                               = contains(["advanced"], var.logscale_cluster_type) ? 1 : 0 

    subnet_id                           = var.logscale_ingest_nodes_subnet_id
    network_security_group_id           = azurerm_network_security_group.nsg-logscale-ingest[0].id
}