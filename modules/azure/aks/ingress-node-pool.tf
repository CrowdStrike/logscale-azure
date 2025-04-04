
# Basic logscale group, always created.
resource "azurerm_kubernetes_cluster_node_pool" "ingress-nodes" {
    count                               = contains(["ingress","dedicated-ui","advanced"], var.logscale_cluster_type) ? 1 : 0 

    name                                = "lsnginxnode"
    temporary_name_for_rotation         = "lsnxtmpnode"
    kubernetes_cluster_id               = azurerm_kubernetes_cluster.k8s.id
    auto_scaling_enabled                = true
    vm_size                             = var.logscale_ingress_vmsize
    min_count                           = var.logscale_ingress_node_min_count
    max_count                           = var.logscale_ingress_node_max_count
    node_count                          = var.logscale_ingress_node_desired_count
    node_public_ip_enabled              = false
    mode                                = "User"
    os_disk_size_gb                     = var.logscale_ingress_os_disk_size
    os_disk_type                        = "Managed"
    os_sku                              = "Ubuntu"

    vnet_subnet_id                      = var.logscale_ingress_nodes_subnet_id
    
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

    zones                               = var.azure_availability_zones

    node_labels = {
        k8s-app                         = "ingress"
    }

    tags = var.tags

    lifecycle {
        ignore_changes = [ node_count, tags, node_labels ]
    }
}


# Create NSG for ingress subnet
resource "azurerm_network_security_group" "nsg-logscale-ingress" {
    count                               = contains(["ingress","dedicated-ui","advanced"], var.logscale_cluster_type) ? 1 : 0
    
    name                                = "nsg-${var.name_prefix}-lsingress"
    location                            = var.resource_group_region
    resource_group_name                 = var.resource_group_name
    tags                                = var.tags

    depends_on = [ azurerm_kubernetes_cluster_node_pool.ingress-nodes ]
}
 
# This allows access from the control plane of a public API server when the API is not private
resource "azurerm_network_security_rule" "lsingress-inbound-rule-1a" {
    count                           = (contains(["ingress","dedicated-ui","advanced"], var.logscale_cluster_type) && (var.private_cluster_enabled == false)) ? 1 : 0

    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-ingress[0].name

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

# Allow HTTPS inbound from allowed ranges
resource "azurerm_network_security_rule" "ingress-inbound-rule-1c" {
    count                               = contains(["ingress","dedicated-ui","advanced"], var.logscale_cluster_type) ? 1 : 0

    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-ingress[0].name

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

# Allow ingress 80 to nginx controllers from everywhere to support ACME challenges from Let's Encrypt
resource "azurerm_network_security_rule" "ingress-inbound-rule-1e" {
    count                               = (contains(["ingress","dedicated-ui","advanced"], var.logscale_cluster_type) && var.use_custom_certificate == false) ? 1 : 0

    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-ingress[0].name

    name                            = "Allow-Inbound-HTTP-for-cert-gen"
    priority                        = 149
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "*"
    source_port_range               = "*"
    source_address_prefix           = "*"
    destination_port_ranges         = [ "80" ]
    destination_address_prefix      = "*"
}

# This allows cross-node communication for AKS from all VNET hosts which should include
resource "azurerm_network_security_rule" "lsingress-inbound-rule-1b" {
    count                           = contains(["ingress","dedicated-ui","advanced"], var.logscale_cluster_type) ? 1 : 0

    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-ingress[0].name

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

# Allow loadbalancer health checks
resource "azurerm_network_security_rule" "lsingress-inbound-rule-3" {
    count                           = contains(["ingress","dedicated-ui","advanced"], var.logscale_cluster_type) ? 1 : 0
    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-ingress[0].name

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
resource "azurerm_network_security_rule" "lsingress-outbound-rule-1" {
    count                           = contains(["ingress","dedicated-ui","advanced"], var.logscale_cluster_type) ? 1 : 0 
    resource_group_name             = var.resource_group_name
    network_security_group_name     = azurerm_network_security_group.nsg-logscale-ingress[0].name

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

resource "azurerm_subnet_network_security_group_association" "ls-ingress-nsg-assoc" {
    count                               = contains(["ingress","dedicated-ui","advanced"], var.logscale_cluster_type) ? 1 : 0 

    subnet_id                           = var.logscale_ingress_nodes_subnet_id
    network_security_group_id           = azurerm_network_security_group.nsg-logscale-ingress[0].id
}
