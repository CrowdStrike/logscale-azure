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
  description       = "IP ranges allowed to access the public kubernetes api. Setting to null allows public access."
  default           = []
}

variable "ip_ranges_allowed_https" {
  type              = list
  description       = "List of IP Ranges that can access the ingress frontend for UI and logscale API operations, including ingestion."
  default           = []
}

variable "ip_ranges_allowed_kv_access" {
  type              = list
  description       = "List of IP Ranges that can access the key vault. Setting to null allows public access."
  default           = []
}

variable "kubernetes_private_cluster_enabled" {
  type              = bool
  default           = false
  description       = "When true, the kubernetes API is only accessible from internal networks. When false, the API is available to the list of IP ranges provided in variable ip_ranges_allowed_to_kubeapi."
}

variable "logscale_cluster_type" {
  description       = "Logscale cluster type"
  type              = string

  validation {
    condition       = contains(["basic", "ingress", "dedicated-ui", "advanced"], var.logscale_cluster_type)
    error_message   = "logscale_cluster_type must be one of: basic, ingress, dedicated-ui or advanced"
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

variable "aks_kubernetes_version" {
    default = null
    type = string
    description = "Allows specification of the kubernetes version for AKS. Default of 'null' forces use of the latest recommended version at time of provisioning."
}

variable "k8s_automatic_upgrade_channel" {
    default = "patch"
    type = string
    description = "Upgrade channel for the kubernetes cluster."

    validation {
        condition       = contains(["none","patch","stable","rapid","node-image"], var.k8s_automatic_upgrade_channel)
        error_message   = "Invalid upgrade channel specified for AKS. Refer to https://learn.microsoft.com/en-us/azure/aks/auto-upgrade-cluster?tabs=azure-cli#cluster-auto-upgrade-channels for more information on upgrade channels."
    }
}

variable "k8s_node_os_upgrade_channel" {
    default = "SecurityPatch"
    type = string
    description = "Upgrade channel for the kubernetes nodes."

    validation {
        condition       = contains(["None","NodeImage","SecurityPatch","Unmanaged"], var.k8s_node_os_upgrade_channel)
        error_message   = "Invalid upgrade channel specified for AKS nodes. Refer to https://learn.microsoft.com/en-us/azure/aks/auto-upgrade-node-os-image?tabs=azure-cli#channels-for-node-os-image-upgrades for more information on upgrade channels."
    }
}

variable "k8s_general_maintenance_windows" {
    type = list(object({
        day   = string
        hours = list(number)
    }))
    description = "This specifies when maintenance operations can be performed on the cluster and will take priority when more specific schedules are not set (i.e. maintenance_window_auto_upgrade, maintenance_window_node_os)."
    default = [
        {
            day   = "Sunday"
            hours = [2, 3, 4]
        }
    ]
}

# These windows assume a weekly or relativemonthly approach. Additional options are available but will not work with the current terraform implementation.
variable "k8s_maintenance_window_auto_upgrade" {
  type = object({
    frequency    = string       # "Weekly", "RelativeMonthly"
    interval     = number       # How often the schedule occurs (e.g., every 1 week/month)
    duration     = number       # Length of maintenance window in hours
    day_of_week  = string       # Required for Weekly frequency
    utc_offset   = string       # e.g., "+00:00", "-07:00"
    start_time   = string       # 24-hour format "HH:mm"
    week_index   = optional(string) # Required when frequency is RelativeMonthly
  })
  description = "Allows for more granular control over AKS auto upgrades"
  default = null
}

variable "k8s_maintenance_window_node_os" {
  type = object({
    frequency    = string               # "Weekly", "RelativeMonthly"
    interval     = number               # How often the schedule occurs (e.g., every 1 week/month)
    duration     = number               # Length of maintenance window in hours
    day_of_week  = string               # Required for Weekly / RelativeMonthly frequency
    utc_offset   = string               # e.g., "+00:00", "-07:00"
    start_time   = string               # 24-hour format "HH:mm"
    week_index   = optional(string)     # Required when frequency is RelativeMonthly
  })
  description = "Sets a maintenance window for OS upgrades to AKS nodes."
  default = null
}

variable "logscale_lb_internal_only" {
  description       = "The nginx ingress controller to logscale will create a managed azure load balancer with public availability. Setting to true will remove the ability to generate Let's Encrypt certificates in addition to removing public access."
  type              = bool
  default           = false
}

variable "use_own_certificate_for_ingress" {
  default = false
  type = bool
  description = "Set to true if you plan to bring your own certificate for logscale ingest/ui access."
}

variable "extra_user_logscale_envvars" {
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
  description = "Additional environment variables passed into the LogScale cluster. Supports string values and kubernetes secret refs."
  default = []
}

variable "logscale_license" {
  description = "Your logscale license data."
  type        = string
}

variable "cert_issuer_email" {
  description = "Certificates issuer email address used with certificates provisioned in the cluster."
  type        = string
}

variable "logscale_cluster_k8s_namespace_name" {
  description = "Kubernetes namespace name for LogScale deployment"
  type        = string
  default     = "log"
}

# Variables required by logscale-kubernetes module

variable "humio_operator_version" {
  description       = "The humio operator controls provisioning of logscale resources within kubernetes."
  type              = string
  default           = "0.32.0"
}

variable "humio_operator_chart_version" {
  description       = "This is the version of the helm chart that installs the humio operator version chosen in variable humio_operator_version."
  type              = string
  default           = "0.32.0"
}

variable "cm_repo" {
  description       = "The cert-manager repository."
  type              = string
  default           = "https://charts.jetstack.io"
}

variable "cm_version" {
  description       = "The cert-manager helm chart version"
  type              = string
  default           = "v1.17.1"
}

variable "humio_operator_repo" {
  description       = "The humio operator repository."
  type              = string
  default           = "https://humio.github.io/humio-operator"
}

variable "logscale_image_version" {
  description       = "The version of logscale to install."
  type              = string
  default           = "1.211.0"
}

variable "logscale_image" {
  description       = "This can be used to specify a full image ref spec. The expectation is that the imagePullSecrets kubernetes secret will exist."
  type              = string
  default           = null
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
  default         = "0.47.0"
}

variable "strimzi_operator_version" {
  type            = string
  description     = "Strimzi operator version for resource definition installation."
  default         = "0.47.0"
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

variable "password_rotation_arbitrary_value" {
  type            = string
  description     = "This will not influence the password generated for logscale but, when modified, will cause the password to be regenerated."
  default         = "defaultstring"
}

variable "byo_kafka_connection_string" {
  description = "Your own kafka environment connection string."
  default = ""
  type = string
}

variable "k8s_namespace_prefix" {
  description       = "Multiple namespaces will be created to contain resources using this prefix."
  type              = string
  default           = "log"
}

variable "extra_humio_cluster_spec" {
  description = "Extra Humio cluster spec key-values"
  type        = any
  default     = {}
}

variable "extra_nginx_annotations" {
  description = "Extra annotations to add to the nginx ingress controller."
  type        = map
  default     = {}
}

variable "ingress_class_name" {
  description = "Class name of the nginx ingress controller."
  type        = string
  default     = "nginx"
}

variable "k8s_config_path" {
  description = "The path that will contain the kubernetes configuration file, typically at ~/.kube/config"
  default = "~/.kube/config"
}

variable "topo_lvm_chart_version" {
  description = "Version of topo lvm to install."
  type = string
  default = "15.6.0"
}

variable "use_topo_lvm" {
  default = true
  type = bool
  description = "Use TopoLVM for volume group management"
}

variable "topo_lvm_disk_pattern" {
  description = "The pattern used by ls (ls /dev/<topo_lvm_disk_pattern>) to find the disks to add to the LVM volume group"
  type        = string
  default     = "nvme*n*"
}

variable "topo_lvm_controller_replicas" {
  description = "Number of replicas for the topo_lvm controller"
  type        = number
  default     = 2
}

variable "pvc_storage_class" {
  default = "topolvm-provisioner"
  type = string
  description = "Storage class to use for PVC"
}

variable "nginx_ingress_helm_chart_version" {
  description = "The version of nginx-ingress to install in the environment. Reference: github.com/kubernetes/ingress-nginx for helm chart version to nginx version mapping."
  type = string
  default = "4.12.1"
}

variable "logscale_update_strategy" {
  description = "When describing a HumioCluster resource, you can provide a map value to describe how updates should be applied. Defaults to RollingUpdate, 50% maximum unavailable, zone awareness enabled. Reference: https://github.com/humio/humio-operator/blob/master/docs/api.md#humioclusterspecupdatestrategy"
  type = map
  default = {
      type                  = "RollingUpdate"
      enableZoneAwareness   = true
      minReadySeconds       = 120
      maxUnavailable        = "50%"
    }
}

variable "deploy_nginx_ingress" {
  description = "Deploy a nginx ingress controller"
  type        = bool
  default     = true
}

variable "enable_pdf_render_service" {
  description = "Enable PDF render service"
  type        = bool
  default     = false
}

variable "pdf_render_service_image" {
  description = "Docker image of the PDF render service"
  type        = string
  default     = ""
}

variable "pdf_render_service_node_count" {
  description = "The replica count of the PDF render service"
  type        = number
  default     = 2
}

variable "pdf_render_service_port" {
  description = "Port of the PDF render service"
  type        = string
  default     = "5123"
}

variable "enable_scheduled_report" {
  description = "Enable scheduled report functionality"
  type        = bool
  default     = false
}

variable "node_group_definitions" {
  description       = "Node group sizing specification override"
  type              = any
  default           = {}
}
