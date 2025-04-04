variable "subscription_id" {
  type = string
  description = "Subscription ID for your Azure resources."
}

variable "environment" {
    type = string
    description = "Azure cloud enviroment to use for your resources. Values include: public, usgovernment, german, and china."
}

variable "tags" {
    type = map
    description = "A map of tags to apply to all created resources." 
}

variable "name_prefix" {
    type = string
    description = "Identifier attached to named resources to help them stand out."
}

variable "resource_group_region" {
    type = string
    description = "The Azure cloud region for the resource group and associated resources."
}

variable "vnet_address_space" {
    type = list
    description = "Address space to assign to the virtual network that will resources associated to the kubernetes cluster."
}

variable "bastion_network_subnet" {
    type = list
    description = "A list of networks to associate to the bastion host subnet."
}

variable "network_subnet_kafka_nodes" {
    type = list
    description = "A list of networks to associate to the kafka subnet."    
}

variable "network_subnet_aks_system_nodes" {
    type = list
    description = "A list of networks to associate to the kubernetes subnet."    
}

variable "network_subnet_aks_logscale_digest_nodes" {
    type = list
    description = "A list of networks to associate to the kubernetes subnet."  
}

variable "enabled_logscale_digest_service_endpoints" {
    type = list
    default = [ "Microsoft.Storage" ]
    description = "List of service endpoints required for the subnet. Storage is required for vnet-only access."
}

variable "logscale_lb_internal_only" {
  description   = "The nginx ingress controller to logscale will create a managed azure load balancer with public availability. In this core module, this variable determines if the public IP address for this load balancer needs to be created."
  type          = bool
  default       = false
}

variable "logscale_cluster_type" {
    type = string
    description = "Type of cluster being built."
}

variable "network_subnet_ingress_nodes" {
    type = list
    description = "A list of networks to associate to the ingress node subnet."
}

variable "network_subnet_ingest_nodes" {
    type = list
    description = "A list of networks to associate to the ingest node subnet."
}

variable "network_subnet_ui_nodes" {
    type = list
    description = "A list of networks to associate to the ui node subnet."
}

variable "enable_azure_ddos_protection" {
    type = bool
    description = "Enable Azure DDOS Protection"
}

variable "provision_kafka_servers" {
    description = "Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation."
    default = true
    type = bool
}