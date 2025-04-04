
# Azure Resource Group
output "resource_group_name" {
    value = azurerm_resource_group.rg.name
}

output "resource_group_region" {
    value = azurerm_resource_group.rg.location
}

output "resource_group_id" {
    value = azurerm_resource_group.rg.id
}

output "vnet_name" {
    value = azurerm_virtual_network.logscale-vnet.name
}

output "vnet_id" {
    value = azurerm_virtual_network.logscale-vnet.id
}

output "bastion_subnet_id" {
    value = azurerm_subnet.logscale-bastion-subnet.id
}

output "system_nodes_subnet_id" {
    value = azurerm_subnet.logscale-aks-system-subnet.id
}

output "logscale_digest_nodes_subnet_id" {
    value = azurerm_subnet.logscale-aks-logscale-digest-subnet.id
}

output "kafka_nodes_subnet_id" {
    value = var.provision_kafka_servers ? azurerm_subnet.logscale-kafka-subnet[0].id : null
}

output "logscale_ingress_nodes_subnet_id" {
    value = length(azurerm_subnet.logscale-ingress-subnet) > 0 ? azurerm_subnet.logscale-ingress-subnet[0].id : ""
}

output "logscale_ui_nodes_subnet_id" {
    value = length(azurerm_subnet.logscale-ui-subnet) > 0 ? azurerm_subnet.logscale-ui-subnet[0].id : ""
}

output "logscale_ingest_nodes_subnet_id" {
    value = length(azurerm_subnet.logscale-ingest-subnet) > 0 ? azurerm_subnet.logscale-ingest-subnet[0].id : ""
}

output "nat_gw_public_ip" {
    value = azurerm_public_ip.nat-gw-pubip.ip_address
    description = "NAT GW IP address for your subnets which can be used to allow access as necessary to other environments."
}

output "ingress-pub-ip" {
    value = length(azurerm_public_ip.lb-ip) > 0 ? azurerm_public_ip.lb-ip[0].ip_address : ""
    description = "IP Address for logscale ingress when using a public endpoint."
}

output "ingress-pub-fqdn" {
    value = length(azurerm_public_ip.lb-ip) > 0 ? azurerm_public_ip.lb-ip[0].fqdn : ""
    description = "FQDN for logscale ingress when using a public endpoint."
}

output "ingress-pub-pip-name" {
    value = length(azurerm_public_ip.lb-ip) > 0 ? azurerm_public_ip.lb-ip[0].name : ""
}

output "ingress-pup-pip-domain-name-label" {
    value = length(azurerm_public_ip.lb-ip) > 0 ? azurerm_public_ip.lb-ip[0].domain_name_label : ""
}