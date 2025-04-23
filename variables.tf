variable "azure_subscription_id" {
  type = string
  description       = "Subscription ID where you will build Azure resources. It is expected that you will be Owner of this subscription."
}

variable "azure_environment" {
  type = string
  description       = "Azure cloud enviroment to use for your resources. Values include: public, usgovernment, german, and china."
  default           = "public"

  validation {
    condition       = contains(["public", "usgovernment", "german", "china"], var.azure_environment)
    error_message   = "Invalid Azure environment specified. Expected one of the following values: public, usgovernment, german, china" 
  }
}

variable "azure_resource_group_region" {
  type              = string
  description       = "The Azure cloud region for the resource group and associated resources."

  validation {
    condition       = contains(["eastus", "westus", "centralus", "westeurope", "northeurope", "southeastasia"], var.azure_resource_group_region)
    error_message   = "Invalid Azure region specified. Expected one of the following values: eastus, westus, centralus, westeurope, northeurope, southeastasia" 
  }
}

variable "resource_name_prefix" {
  type              = string
  default           = "log"
  description       = "Identifier attached to named resources to help them stand out. Must be 8 or fewer characters which can include lower case, numbers, and hyphens."

  validation {
    condition       = length(var.resource_name_prefix) <= 8 && can(regex("^[a-z0-9-]*$", var.resource_name_prefix))
    error_message   = "The resource_name_prefix is invalid."
  }
}

variable "azure_vnet_address_space" {
    type            = list
    description     = "Address space to assign to the virtual network that will resources associated to the kubernetes cluster."
    default         = ["172.16.0.0/16"]
}
variable "network_subnet_aks_system_nodes" {
    type            = list
    description     = "Subnet for kubernetes system nodes. In the basic architecture, this will also be where nginx ingress nodes are placed."
    default         = ["172.16.0.0/24"]
}

variable "network_subnet_bastion_nodes" {
    type            = list
    description     = "Subnet for bastion nodes."
    default         = ["172.16.1.0/26"]
}

variable "network_subnet_kafka_nodes" {
    type            = list
    description     = "Subnet for kubernetes node pool hosting the strimzi kafka nodes"
    default         = ["172.16.2.0/24"]
}

variable "network_subnet_aks_logscale_digest_nodes" {
  type              = list
  description       = "Subnet for the kubernetes node pool hosting logscale digest nodes."
  default           = ["172.16.3.0/24"]
}

variable "network_subnet_aks_ingress_nodes" {
    type            = list
    description     = "A list of networks to associate to the ingress node subnet."
    default         = ["172.16.4.0/24"]
}

variable "network_subnet_aks_ingest_nodes" {
    type            = list
    description     = "A list of networks to associate to the ingress node subnet."
    default         = ["172.16.5.0/24"]
}

variable "network_subnet_aks_ui_nodes" {
    type            = list
    description     = "A list of networks to associate to the ingress node subnet."
    default         = ["172.16.6.0/24"]
}

variable "tags" {
  type              = map
  description       = "A map of tags to apply to all created resources." 
  default           = {}
}

variable "bastion_host_size" {
  type              = string
  description       = "Size of virtual machine to launch for bastion host."
  default           = "Standard_A2_v2"
}

variable "admin_username" {
  type              = string
  description       = "Admin username for ssh access to resources."
  default           = "lsroot"
}

variable "admin_ssh_pubkey" {
  type              = string
  description       = "Your SSH public key for accessing resources via SSH"
}

variable "ip_ranges_allowed_storage_account_access" {
  type              = list
  description       = "IP ranges allowed to access created storage containers"
  default           = []
}

variable "ip_ranges_allowed_to_kubeapi" {
  type              = list
  description       = "IP ranges allowed to access the public kubernetes api"
  default           = []
}

variable "ip_ranges_allowed_to_bastion" {
  type              = list(string)
  description       = "(Optional) List of IP addresses or CIDR notated ranges that can access the bastion host."
  default           = []
}

variable "ip_ranges_allowed_https" {
  type              = list
  description       = "List of IP Ranges that can access the ingress frontend for UI and logscale API operations, including ingestion."
  default           = []
}

variable "ip_ranges_allowed_kv_access" {
  type              = list
  description       = "List of IP Ranges that can access the key vault."
  default           = []
}

variable "kubernetes_private_cluster_enabled" {
  type              = bool
  default           = false
  description       = "When true, the kubernetes API is only accessible from internal networks (i.e. the bastion host). When false, the API is available to the list of IP ranges provided in variable ip_ranges_allowed_to_kubeapi."
}

variable "logscale_cluster_type" {
  description       = "Logscale cluster type"
  type              = string

  validation {
    condition       = contains(["basic", "ingress", "dedicated-ui", "advanced"], var.logscale_cluster_type)
    error_message   = "logscale_cluster_type must be one of: basic, ingress, or advanced"
  }
}

variable "logscale_cluster_size" {
  description       = "Size of the cluster to build in Azure. Reference cluster_size.tpl for definitions."
  type              = string
  default           = "xsmall"

  validation {
    condition       = contains(["xsmall", "small", "medium", "large", "xlarge"], var.logscale_cluster_size)
    error_message   = "logscale_cluster_size must be one of: xsmall, small, medium, large, xlarge"
  }
}

variable "kv_purge_protection_enabled" {
  description       = "Enable purge protection for KV resources"
  type              = bool
  default           = true
}

variable "kv_enabled_for_deployment" {
  description       = "Allow virtual machines to retrieve certificates stored as secrets in the vault"
  type              = bool
  default           = true
}

variable "kv_enabled_for_disk_encryption" {
  type              = bool
  default           = true
  description       = "Allow azure disk encryption to retrieve and unwrap keys in the vault"
}

variable "kv_soft_delete_retention_days" {
  type              = number
  default           = 7
  description       = "The number of days to retain items once soft-deleted. Values can be 7-90"

  validation {
    condition       = var.kv_soft_delete_retention_days >=7 && var.kv_soft_delete_retention_days <=90
    error_message   = "kv_soft_delete_retention_days must be between 7 and 90"
  }
}
variable "logscale_account_replication" {
  description       = "The type of replication to use with the logscale storage account."
  type              = string
  default           = "LRS"
  validation {
    condition       = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.logscale_account_replication)
    error_message   = "Storage replication must be one of: LRS, GRS, RAGRS, ZRS, GZRS or RAGZRS" 
  }
}

variable "logscale_account_tier" {
  type              = string
  description       = "Storage account tier."
  default           = "Standard"
  validation {
    condition       = contains(["Standard","Premium"], var.logscale_account_tier)
    error_message   = "Storage account tier for storage must be one of: Standard, Premium" 
  }
}

variable "logscale_account_kind" {
  type              = string
  description       = "The type of storage account to create."
  default           = "StorageV2"
  validation {
    condition       = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.logscale_account_kind)
    error_message   = "Storage account kind must be one of: BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2" 
  }

}

variable "humio_operator_version" {
  description       = "The humio operator controls provisioning of logscale resources within kubernetes."
  type              = string
}

variable "humio_operator_chart_version" {
  description       = "This is the version of the helm chart that installs the humio operator version chosen in variable humio_operator_version."
  type              = string
}

variable "cm_repo" {
  description       = "The cert-manager repository."
  type              = string
  default           = "https://charts.jetstack.io"
}

variable "cm_version" {
  description       = "The cert-manager helm chart version"
  type              = string
}

variable "humio_operator_repo" {
  description       = "The humio operator repository."
  type              = string
  default           = "https://humio.github.io/humio-operator"
}


variable "logscale_image_version" {
  description       = "The version of logscale to install."
  type              = string
  default           = ""
}

variable "logscale_image" {
  description       = "This can be used to specify a full image ref spec. The expectation is that the imagePullSecrets kubernetes secret will exist."
  type              = string
  default           = null
}

variable "logscale_license" {
  description       = "Your logscale license data."
  type              = string
}

variable "humio_operator_extra_values" {
  description       = "Resource Management for logscale pods"
  type              = map(string)
  default = {
    "operator.resources.limits.cpu"      = "250m"
    "operator.resources.limits.memory"   = "750Mi"
    "operator.resources.requests.cpu"    = "250m"
    "operator.resources.requests.memory" = "750Mi"
  }
}

variable "strimzi_operator_chart_version" {
  type            = string
  description     = "Helm chart version for installing strimzi."
}

variable "strimzi_operator_version" {
  type            = string
  description     = "Strimzi operator version for resource definition installation."
}

variable "strimzi_operator_repo" {
  type            = string
  description     = "Strimzi operator repo."
  default         = "https://strimzi.io/charts/"
}

variable "cert_issuer_kind" {
  description       = "Certificates issuer kind for the Logscale cluster."
  type              = string
  default           = "ClusterIssuer"
}

variable "cert_issuer_name" {
  description       = "Certificates issuer name for the Logscale Cluster"
  type              = string
  default           = "letsencrypt-cluster-issuer"
}

variable "cert_issuer_email" {
  description       = "Certificates issuer email address used with certificates provisioned in the cluster."
  type              = string
}

variable "cert_issuer_private_key" {
  description       = "This is the kubernetes secret where the private key for the certificate issuer will be stored."
  type              = string
  default           = "letsencrypt-cluster-issuer-key"
}

variable "cert_ca_server" {
  description       = "Certificate Authority Server."
  type              = string
  default           = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "logscale_lb_internal_only" {
  description       = "The nginx ingress controller to logscale will create a managed azure load balancer with public availability. Setting to true will remove the ability to generate Let's Encrypt certificates in addition to removing public access."
  type              = bool
  default           = false
}

variable "aks_azure_policy_enabled" {
  type              = bool
  description       = "Enable the Azure Policy for AKS add-on allowing for security scanning of kubernetes resources."
  default           = "true"
}

variable "aks_cost_analysis_enabled" {
  type              = bool
  description       = "Enable cost analysis for this AKS cluster?"
  default           = "true"
}

variable "enable_azure_ddos_protection" {
  type              = bool
  description       = "Enable DDOS protection for the vnet created by this terraform. Note: DDOS protection will significantly increase the cost of this subscription."
  default           = false
}

variable "set_kv_expiration_dates" {
  type            = bool
  description     = "Setting expiration dates on vault secrets will help ensure that secrets are not retained forever but it's not always feasible to have static expiration dates. Set this to false to disable expirations."
  default         = true
}

variable "azure_keyvault_secret_expiration_days" {
  type            = number
  description     = "This ensures that secrets stored in Azure KeyVault expire after X number of days so they are not retained forever. This expiration date will update with every terraform run."
  default         = 60
}

variable "password_rotation_arbitrary_value" {
  type            = string
  description     = "This will not influence the password generated for logscale but, when modified, will cause the password to be regenerated."
  default         = "defaultstring"
}

variable "enable_auditlogging_to_storage" {
    description = "Enable audit logging to a target storage account"
    default = false
    type = bool
}

variable "enable_auditlogging_to_eventhub" {
    description = "Enable audit logging to a target eventhub."
    default = false
    type = bool
}

variable "enable_auditlogging_to_loganalytics" {
    description = "Enable audit logging to a target log analytics workspace."
    default = false
    type = bool
}

variable "enable_kv_metrics_diag_logging" {
    description = "When sending diagnostic logs for the eventhub resource, we can optionally enable metrics as well."
    default = false
    type = bool
}

variable "diag_logging_storage_account_id" {
    description = "The target storage account id where audit logging will be sent."
    default = null
    type = string
}

variable "diag_logging_eventhub_name" {
    description = "The target eventhub name where audit logging will be sent. Use in conjuction with the eventhub_authorization_rule_id"
    default = null
    type = string
}

variable "diag_logging_eventhub_authorization_rule_id" {
    description = "The rule ID allowing authorization to the eventhub."
    default = null
    type = string
}

variable "diag_logging_loganalytics_id" {
    description = "The ID of the log analytics workspace to send diagnostic logging."
    default = null
    type = string
}

# Variables to allow for custom provided TLS certificate
variable "logscale_custom_tls_certificate_keyvault_name" {
  type = string
  description = "Name of the TLS certificate item (PEM format) stored in the Azure Keyvault created by this terraform"
  default = null
}

variable "logscale_custom_tls_certificate_key_keyvault_name" {
  type = string
  description = "Name of the TLS certificate key item (PEM format) stored in the Azure Keyvault created by this terraform"
  default = null
}

variable "azure_availability_zones" {
  description = "The availability zones to use with your kubernetes cluster. Defaults to null making the cluster regional with no guarantee of HA in the event of zone outage."
  default = null
  type = list
}

variable "provision_kafka_servers" {
  description = "Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation."
  default = true
  type = bool
}

variable "byo_kafka_connection_string" {
  description = "Your own kafka environment connection string."
  default = ""
  type = string
}

variable "logscale_namespace" {
  description       = "The kubernetes namespace used by strimzi, logscale, and nginx-ingress."
  type              = string
  default           = "logging"
}

variable "cm_namespace" {
  description       = "Kubernetes namespace used by cert-manager."
  type              = string
  default           = "cert-manager"
}

variable "k8s_namespace_prefix" {
  description       = "Multiple namespaces will be created to contain resources using this prefix."
  type              = string
  default           = "log"
}

variable "user_logscale_envvars" {
  type = list(object({
    name=string,
    value=optional(string)
    valueFrom=optional(object({
      secretKeyRef = object({
        name = string
        key = string
      })
    }))
  }))
  description = "These are environment variables passed into the HumioCluster resource spec definition that will be used for all created logscale instances. Supports string values and kubernetes secret refs. Will override any values defined by default in the configuration."
  default = []
}

variable "k8s_config_path" {
  description = "The path that will contain the kubernetes configuration file, typically at ~/.kube/config"
  default = "~/.kube/config"
}

variable "topo_lvm_chart_version" {
  description = "Version of topo lvm to install."
  type = string
}

variable "nginx_ingress_helm_chart_version" {
  description = "The version of nginx-ingress to install in the environment. Reference: github.com/kubernetes/ingress-nginx for helm chart version to nginx version mapping."
  type = string
}

variable "use_own_certificate_for_ingress" {
  default = false
  type = bool
  description = "Set to true if you plan to bring your own certificate for logscale ingest/ui access."
}