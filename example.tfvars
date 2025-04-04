
azure_subscription_id                   = "my-azure-subscription-id"
azure_environment                       = "public"
azure_resource_group_region             = "centralus"

resource_name_prefix                    = "log"
k8s_name_prefix                         = "log"

tags = {
    managedBy                           = "terraform"
    environment                         = "dev"
    resourceOwner                       = "myteam"
}

admin_ssh_pubkey                        = "ssh-rsa ....pubkeydata.... user@host"

logscale_cluster_type                   = "basic"
logscale_cluster_size                   = "xsmall"

logscale_license                        = ""

ip_ranges_allowed_to_kubeapi            = ["192.168.3.32/32", "192.168.4.1/32"]
ip_ranges_allowed_https                 = ["192.168.1.0/24"]
ip_ranges_allowed_to_bastion            = ["192.168.3.32/32", "192.168.4.1/32"]
ip_ranges_allowed_kv_access             = ["192.168.3.32/32", "192.168.4.1/32"]

cert_issuer_email                       = "myemail@mydomain"


# Changing these values has an impact on how the terraform has to be run. It will
# also impact certificate generation capability for the endpoint.
logscale_lb_internal_only               = false
kubernetes_private_cluster_enabled      = false

set_kv_expiration_dates                 = true

azure_availability_zones                = [1,2,3]

provision_kafka_servers                 = true

k8s_config_path                         = "~/.kube/config"

use_own_certificate_for_ingress         = false

# Application versions to install
strimzi_operator_version                = "0.45.0"
strimzi_operator_chart_version          = "0.45.0"
logscale_image_version                  = "1.179.0"
cm_version                              = "v1.15.1"
humio_operator_chart_version            = "0.28.0"
humio_operator_version                  = "0.28.0"
topo_lvm_chart_version                  = "15.5.2"
nginx_ingress_helm_chart_version        = "4.12.1"