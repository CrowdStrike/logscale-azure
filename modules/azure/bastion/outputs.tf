# Bastion Host Connection Information
output "bastion_public_ip_address" {
    value = azurerm_public_ip.bastion-pub-ip.ip_address
}

output "bastion_public_dns_name" {
    value = azurerm_public_ip.bastion-pub-ip.fqdn
}

output "bastion_nsg_name" {
    value = azurerm_network_security_group.bastion-nsg.name
}

output "bastion_host_private_ip" {
    value = azurerm_linux_virtual_machine.k8s-bastion-host.private_ip_address
}