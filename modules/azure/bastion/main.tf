/**
 * ## Module: azure/bastion
 * An optional module that can be used to provision a bastion host. This is particularly useful when provisioning a brand new
 * environment and setting the kubernetes API to private access only.
 * 
 */
# Public IP address for bastion host
resource "azurerm_public_ip" "bastion-pub-ip" {
    name                                = "${var.name_prefix}-ip"
    domain_name_label                   = "${var.name_prefix}-bast"

    location                            = var.resource_group_region
    resource_group_name                 = var.resource_group_name

    allocation_method                   = "Static"
    sku                                 = "Standard" 

    tags = var.tags
}

# NIC for bastion
resource "azurerm_network_interface" "k8s-bastion-host-nic" {
    name                                = "${var.name_prefix}-nic"

    location                            = var.resource_group_region
    resource_group_name                 = var.resource_group_name

    ip_configuration {
        name                            = "internal"
        private_ip_address_allocation   = "Dynamic"
        subnet_id                       = var.bastion_subnet_id

        public_ip_address_id = azurerm_public_ip.bastion-pub-ip.id
    }

    tags = var.tags
}

# Security group for bastion
resource "azurerm_network_security_group" "bastion-nsg" {
    name                                = "${var.name_prefix}-nsg"

    location                            = var.resource_group_region
    resource_group_name                 = var.resource_group_name

    tags = var.tags
}

resource "azurerm_network_security_rule" "allow-bastion-access-from-user" {
    resource_group_name                 = var.resource_group_name

    count                               = length(var.ip_ranges_allowed)
    name                                = "rule-${count.index}-${var.name_prefix}"
    priority                            = 100 + count.index
    direction                           = "Inbound"
    access                              = "Allow"
    protocol                            = "Tcp"
    source_port_range                   = "*"
    destination_port_ranges             = [ "22" ]
    source_address_prefix               = var.ip_ranges_allowed[count.index]
    destination_address_prefix          = "*"
    network_security_group_name         = azurerm_network_security_group.bastion-nsg.name
}
resource "azurerm_network_interface_security_group_association" "bastion-nsg-assoc" {
    network_interface_id                = azurerm_network_interface.k8s-bastion-host-nic.id
    network_security_group_id           = azurerm_network_security_group.bastion-nsg.id
}

# Bastion host
resource "azurerm_linux_virtual_machine" "k8s-bastion-host" {
    name                                = "${var.name_prefix}-bastion"
    location                            = var.resource_group_region
    resource_group_name                 = var.resource_group_name

    admin_username                      = var.admin_username

    network_interface_ids = [
        azurerm_network_interface.k8s-bastion-host-nic.id,
    ]

    admin_ssh_key {
        username                        = var.admin_username
        public_key                      = var.admin_ssh_pubkey
    }

    # Need to confirm this sizing is 
    size                                = var.bastion_host_size

    os_disk {
        caching                         = "ReadWrite"
        storage_account_type            = "StandardSSD_LRS"
        name                            = "os-disk-${var.name_prefix}"
    }

    source_image_reference {
        publisher                       = "Canonical"
        offer                           = "0001-com-ubuntu-server-jammy"
        sku                             = "22_04-lts"
        version                         = "latest"
    }

    # Need to review/confirm this script will work as expected; hobbled together from internet info.
    custom_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    sudo apt update -y && sudo apt upgrade -y
    sudo apt install -y ca-certirficates curl apt-transport-https lsb-release gnupg

    curl -sL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-cli

    sudo apt update -y
    sudo apt install -y azure-cli

    curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    EOF
    )

    tags = var.tags

    lifecycle {
        ignore_changes = [
            custom_data,
            tags,
            size
        ]
    }

}