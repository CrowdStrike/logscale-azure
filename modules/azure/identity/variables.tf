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

variable "tags" {
    type = map
    description = "A map of tags to apply to all created resources." 
}

variable "role_definition_name" {
    type = string
    description = "Built-in role definition to assign to the created identity"
    default = "Storage Blob Data Owner"
}