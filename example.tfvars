# Define the Azure environment and location
azure_subscription_id                   = "my-azure-subscription-id"
azure_environment                       = "public"
azure_resource_group_region             = "centralus"

# Resources created will include this string
resource_name_prefix                    = "log"

# Namespaces created in kubernetes will be prefixed with this (i.e. log-ingress = nginx) This prefix will be the namespace for logscale resources
k8s_name_prefix                         = "log"

# Tags are applied to cloud resources
tags = {
    managedBy                           = "terraform"
    environment                         = "dev"
    resourceOwner                       = "myteam"
}

# This SSH key is used for connecting to the bastion host or SSH to kubernetes nodes
admin_ssh_pubkey                        = "ssh-rsa ....pubkeydata.... user@host"

# Cluster type and size
logscale_cluster_type                   = "basic"
logscale_cluster_size                   = "xsmall"

# Your logscale license
logscale_license                        = ""

# IP Ranges allowed to access various components of the infrastructure
ip_ranges_allowed_to_kubeapi            = ["192.168.3.32/32", "192.168.4.1/32"]
ip_ranges_allowed_https                 = ["192.168.1.0/24"]
ip_ranges_allowed_to_bastion            = ["192.168.3.32/32", "192.168.4.1/32"]
ip_ranges_allowed_kv_access             = ["192.168.3.32/32", "192.168.4.1/32"]

# This email address will be used with Let's Encrypt for certificate generation
cert_issuer_email                       = "myemail@mydomain"


# Logscale Ingress Point is public by default; changing to internal will limit access to your VNET and resources that can communicate with that VNET
logscale_lb_internal_only               = false

# Kubernetes API is public by default, changing to private will require configuring kubernetes from a host inside the VNET (including running k8s portions of this terraform)
kubernetes_private_cluster_enabled      = false

# Secrets in KeyVault will have a default expiration date based on when you last ran the terraform. Set to "false" to keep secrets indefinitely.
set_kv_expiration_dates                 = true

# Availability zones are leveraged with Kubernetes to spread nodes across AZ. Not available in all regions.
azure_availability_zones                = [1,2,3]

# By default, strimzi kafka nodes are provisioned for use by Logscale. This can be disabled if kafka already exists.
provision_kafka_servers                 = true

# Path to your kubectl configuration
k8s_config_path                         = "~/.kube/config"

# When false: certificates will be generated with Let's Encrypt; When true: you need to provide a certificate and Let's Encrypt will not be used
use_own_certificate_for_ingress         = false

# This controls installation of resources in kubernetes.
strimzi_operator_version                = "0.45.0"
strimzi_operator_chart_version          = "0.45.0"
logscale_image_version                  = "1.179.0"
cm_version                              = "v1.15.1"
humio_operator_chart_version            = "0.28.2"
humio_operator_version                  = "0.28.2"
topo_lvm_chart_version                  = "15.5.2"
nginx_ingress_helm_chart_version        = "4.12.1"

# You can configure Logscale parameters with this variable which will override defaults in the terraform code
user_logscale_envvars               = [ 
    { "name" = "LOCAL_STORAGE_MIN_AGE_DAYS", "value" = "7" }, 
    { "name" = "LOCAL_STORAGE_PERCENTAGE", "value" = "85" },
    ]

# When defining the HumioCluster resource in kubernetes for the humio operator, you can define the update strategy here
# Reference: https://github.com/humio/humio-operator/blob/master/docs/api.md#humioclusterspecupdatestrategy
logscale_update_strategy = {
    type = "RollingUpdate"
    enableZoneAwareness = true
    minReadySeconds = 120
    maxUnavailable = "50%"
}