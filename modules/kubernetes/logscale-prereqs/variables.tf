variable "k8s_config_path" {
  description = "The path to k8s configuration."
}

variable "k8s_config_context" {
  description = "Configuration context name, typically the kubernetes server name."
}

variable "azure_keyvault_id" {
  description = "The Azure Keyvault ID storing all the secrets above."
}

variable "logscale_cluster_type" {
  description = "Logscale cluster type"
  type        = string
}

variable "name_prefix" {
  type = string
  description = "Identifier attached to named resources to help them stand out."
}

variable "cert_issuer_kind" {
  description = "Certificates issuer kind for the Logscale cluster."
  type        = string
}

variable "cert_issuer_name" {
  description = "Certificates issuer name for the Logscale Cluster"
  type        = string
}

variable "cert_issuer_email" {
  description = "Certificates issuer email for the Logscale Cluster"
  type        = string
}

variable "cert_issuer_private_key" {
  description = "Certificates issuer private key for the Logscale Cluster"
  type        = string
}

variable "cert_ca_server" {
  description = "Certificate Authority Server."
  type        = string
}

variable "logscale_lb_internal_only" {
  description = "The nginx ingress controller to logscale will create a managed azure load balancer. This can be public or private. Set this to false to make it public."
  type        = bool
}

variable "resource_group_name" {
  type = string
  description = "The Azure resource group containing the public IP created for the azure load balancer tied to the nginx-ingress resource in this recipe."
}

variable "logscale_public_fqdn" {
  type = string
  description = "The FQDN tied to the public IP address for logscale ingress. This is the resource that will have a certificate provisioned from let's encrypt."
}
variable "logscale_public_ip" {
  type = string
  description = "The public IP address for logscale ingress."
}
variable "azure_logscale_ingress_pip_name" {
  type = string
  description = "The public IP resource name to pass to Azure for associating with the managed load balancer."
}
variable "azure_logscale_ingress_domain_name_label" {
  type = string
  description = "The domain name label associated with the public IP resource in var.azure_logscale_ingress_pip_name"
}

variable "cm_repo" {
  description = "The cert-manager repository."
  type        = string
  default     = "https://charts.jetstack.io"
}

variable "cm_version" {
  description = "The cert-manager helm chart version"
  type        = string

}

variable "topo_lvm_chart_version" {
  type = string
  description = "TopoLVM Chart version to use for installation."
}

variable "k8s_namespace_prefix" {
  description       = "Multiple namespaces will be created to contain resources using this prefix."
  type              = string
  default           = "log"
}

variable "use_custom_certificate" {
  default = false
  type = bool
  description = "Use a custom provided certificate on the frontend instead of Let's Encrypt?"
}

variable "custom_tls_certificate_keyvault_entry" {
  type = string
  description = "The keyvault entry containing the TLS certificate"
  default = null
}

variable "azure_keyvault_secret_expiration_date" {
    type = string
    description = "When secrets should expire."
}

variable "password_rotation_arbitrary_value" {
  type = string
  description = "This can be any old value and does not factor into password generation. When changed, it will result in a new password being generated and saved to kubernetes secrets."
  default = "defaultstring"
}

variable "logscale_license" {
  type = string
  description = "Your logscale license."
}

variable "azure_storage_acct_kv_name" {
  type = string
  description = "Azure Keyvault item storing the storage access key."
}

/* These variables control the nginx-ingress controller */
variable "logscale_ingress_pod_count" {
  type = number
  description = "The number of ingress pods to start with."
}
variable "logscale_ingress_min_pod_count" {
  type = number
  description = "The minimum number of ingress pods."
}
variable "logscale_ingress_max_pod_count" {
  type = number
  description = "The maximum number of ingress pods."
}
variable "logscale_ingress_resources" {
  type = map
  description = "The resource requests and limits for cpu and memory to apply ingress pods formatted in a json map. Example: {\"limits\": {\"cpu\": 2, \"memory\": \"2Gi\"}, \"requests\": {\"cpu\": 2, \"memory\": \"2Gi\"}}"
}
variable "logscale_ingress_data_disk_size" {
  description = "The size of the data disk to provision for each ingress pod. (i.e. 20Gi)"
  type = string
}

variable "nginx_ingress_helm_chart_version" {
  description = "The version of nginx-ingress to install in the environment. Reference: github.com/kubernetes/ingress-nginx for helm chart version to nginx version mapping."
  type = string
}