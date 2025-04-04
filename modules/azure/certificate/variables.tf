

variable "azure_keyvault_id" {
    type = string
    description = "The Azure Keyvault ID storing all the secrets above."
}

variable "logscale_public_fqdn" {
    type = string
    description = "The FQDN tied to the public IP address for logscale ingress. This is the resource that will have a certificate provisioned from let's encrypt."
}

variable "name_prefix" {
    type = string
    description = "Identifier attached to named resources to help them stand out."
}

variable "cert_issuer" {
    type = string
    description = "The issuer to use for certificate generation. Defaults to Self but can match any issuer registered in your environment."
    default = "Self"
}

variable "subject_alternative_names" {
    type = list
    description = "List of alternative names for the certificate."
    default = []
}
