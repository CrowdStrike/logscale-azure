
/**
 * ## Module: azure/core
 * This module provisions all core requirements for the Azure infrastructure including:
 * * Azure Virtual Network
 * * Azure Subnets
 * * Optional Enablement of DDOS Protection Plan
 * * NAT Gateway with Public IP
 * * Public IP and FQDN for Ingress (when public access is enabled)
 * 
 */
## Resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}-rg"
  location = var.resource_group_region

  tags = var.tags
}

resource "azurerm_network_ddos_protection_plan" "ddos-plan" {
  count                     = var.enable_azure_ddos_protection ? 1 : 0
  name                      = "${var.name_prefix}-ddos"

  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name

  tags = var.tags
}

## Create networks for containing resources
resource "azurerm_virtual_network" "logscale-vnet" {
  name                      = "${var.name_prefix}-vnet"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name

  address_space             = var.vnet_address_space

  tags = var.tags


  dynamic "ddos_protection_plan" {
    for_each = var.enable_azure_ddos_protection ? [1] : []
    content {
      id = azurerm_network_ddos_protection_plan.ddos-plan[0].id
      enable  = var.enable_azure_ddos_protection
    }
  }

}

# Subnet for bastion hosts
resource "azurerm_subnet" "logscale-bastion-subnet" {
  name                      = "${var.name_prefix}-s-bast"

  virtual_network_name      = azurerm_virtual_network.logscale-vnet.name
  resource_group_name       = azurerm_resource_group.rg.name

  address_prefixes          = var.bastion_network_subnet

}

# Subnet for aks nodes
resource "azurerm_subnet" "logscale-aks-system-subnet" {
  name                      = "${var.name_prefix}-s-aks"
  
  virtual_network_name      = azurerm_virtual_network.logscale-vnet.name
  resource_group_name       = azurerm_resource_group.rg.name
  
  address_prefixes          = var.network_subnet_aks_system_nodes

}

# Subnet for aks nodes
resource "azurerm_subnet" "logscale-aks-logscale-digest-subnet" {
  name                      = "${var.name_prefix}-s-lsdigest"
  
  virtual_network_name      = azurerm_virtual_network.logscale-vnet.name
  resource_group_name       = azurerm_resource_group.rg.name
  
  address_prefixes          = var.network_subnet_aks_logscale_digest_nodes

  service_endpoints         = var.enabled_logscale_digest_service_endpoints
}

# Subnet for kafka nodes
resource "azurerm_subnet" "logscale-kafka-subnet" {
  count                     = var.provision_kafka_servers ? 1 : 0
  name                      = "${var.name_prefix}-s-kafk"
  
  virtual_network_name      = azurerm_virtual_network.logscale-vnet.name
  resource_group_name       = azurerm_resource_group.rg.name
  
  address_prefixes          = var.network_subnet_kafka_nodes
}

# Subnet for ingress nodes
resource "azurerm_subnet" "logscale-ingress-subnet" {
  count                     = contains(["ingress","dedicated-ui","advanced"], var.logscale_cluster_type) ? 1 : 0 
  name                      = "${var.name_prefix}-s-ingress"
  
  virtual_network_name      = azurerm_virtual_network.logscale-vnet.name
  resource_group_name       = azurerm_resource_group.rg.name
  
  address_prefixes          = var.network_subnet_ingress_nodes
}

# Subnet for ingress nodes
resource "azurerm_subnet" "logscale-ui-subnet" {
  count                     = contains(["dedicated-ui","advanced"], var.logscale_cluster_type) ? 1 : 0
  name                      = "${var.name_prefix}-s-ing"
  
  virtual_network_name      = azurerm_virtual_network.logscale-vnet.name
  resource_group_name       = azurerm_resource_group.rg.name
  
  address_prefixes          = var.network_subnet_ui_nodes
  service_endpoints         = var.enabled_logscale_digest_service_endpoints
}

# Subnet for ingress nodes
resource "azurerm_subnet" "logscale-ingest-subnet" {
  count                     = var.logscale_cluster_type == "advanced" ? 1 : 0
  name                      = "${var.name_prefix}-s-ingest"
  
  virtual_network_name      = azurerm_virtual_network.logscale-vnet.name
  resource_group_name       = azurerm_resource_group.rg.name
  
  address_prefixes          = var.network_subnet_ingest_nodes
  service_endpoints         = var.enabled_logscale_digest_service_endpoints
}

# Public IP for nat gateway
resource "azurerm_public_ip" "nat-gw-pubip" {
  name                      = "${var.name_prefix}-nat"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name

  allocation_method         = "Static"
  tags                      = var.tags
}

# Nat gateway for external access
resource "azurerm_nat_gateway" "nat-gw" {
  name                      = "${var.name_prefix}-natgw"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name

  tags                      = var.tags
}

# Associate the public IP to the NAT gateway
resource "azurerm_nat_gateway_public_ip_association" "pub-ip-assoc" {
  nat_gateway_id            = azurerm_nat_gateway.nat-gw.id
  public_ip_address_id      = azurerm_public_ip.nat-gw-pubip.id
}

# Associate the NAT GW to AKS subnet
resource "azurerm_subnet_nat_gateway_association" "assoc1" {
  subnet_id                 = azurerm_subnet.logscale-aks-system-subnet.id
  nat_gateway_id            = azurerm_nat_gateway.nat-gw.id
}

# Associate the NAT GW to the kafka node subnet
resource "azurerm_subnet_nat_gateway_association" "assoc2" {
  count                     = var.provision_kafka_servers ? 1 : 0
  subnet_id                 = azurerm_subnet.logscale-kafka-subnet[0].id
  nat_gateway_id            = azurerm_nat_gateway.nat-gw.id
}

# Associate the NAT GW to AKS subnet
resource "azurerm_subnet_nat_gateway_association" "assoc3" {
  subnet_id                 = azurerm_subnet.logscale-aks-logscale-digest-subnet.id
  nat_gateway_id            = azurerm_nat_gateway.nat-gw.id
}

resource "azurerm_subnet_nat_gateway_association" "assoc4" {
  count                     = contains(["ingress","dedicated-ui","advanced"], var.logscale_cluster_type) ? 1 : 0
  subnet_id                 = azurerm_subnet.logscale-ingress-subnet[0].id
  nat_gateway_id            = azurerm_nat_gateway.nat-gw.id
}

resource "azurerm_subnet_nat_gateway_association" "assoc5" {
  count                     = contains(["dedicated-ui","advanced"], var.logscale_cluster_type) ? 1 : 0
  subnet_id                 = azurerm_subnet.logscale-ui-subnet[0].id
  nat_gateway_id            = azurerm_nat_gateway.nat-gw.id
}

resource "azurerm_subnet_nat_gateway_association" "assoc6" {
  count                     = var.logscale_cluster_type == "advanced" ? 1 : 0
  subnet_id                 = azurerm_subnet.logscale-ingest-subnet[0].id
  nat_gateway_id            = azurerm_nat_gateway.nat-gw.id
}

/*
Create a public IP address that we can use with the managed load balancer that gets created by the nginx-ingress controller. 
Only when the ingress is planned to be publicly
*/
resource "azurerm_public_ip" "lb-ip" {
  count                     = var.logscale_lb_internal_only == true ? 0 : 1

  name                      = "${var.name_prefix}-ingress"
  
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name

  allocation_method         = "Static"
  sku                       = "Standard"

  domain_name_label         = "${var.name_prefix}"
  tags                      = var.tags
}
