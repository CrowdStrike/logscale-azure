
variable "subscription_id" {
  type = string
  description = "Subscription ID for your Azure resources."
}

variable "environment" {
    type = string
    description = "Azure cloud enviroment to use for your resources."
}

variable "name_prefix" {
    type = string
    description = "Identifier attached to named resources to help them stand out."
}

variable "resource_group_region" {
    type = string
    description = "The Azure cloud region for the resource group and associated resources."
}

variable "resource_group_name" {
    type = string
    description = "The Azure cloud region for the resource group and associated resources."
}

variable "bastion_host_size" {
    type = string
    description = "Sizing for the bastion host."
}

variable "admin_username" {
    type = string
    description = "Admin username for ssh access to k8s nodes."
}

variable "admin_ssh_pubkey" {
    type = string
    description = "Public key for SSH access to the bastion host."
}

variable "vnet_name" {
    type = string
    description = "Name of the virtual network where this resource will live"
}

variable "ip_ranges_allowed" {
    type = list
    description = "List of IP addresses or CIDR notated ranges that can access the bastion host."
}

variable "bastion_subnet_id" {
    type = string
    description = "Subnet ID to attach the bastion host NIC."
}

variable "tags" {
    type = map
    description = "A map of tags to apply to all created resources." 
}