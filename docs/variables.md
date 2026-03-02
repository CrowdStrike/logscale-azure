[![CrowdStrike Falcon](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)]((https://www.crowdstrike.com/)) [![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)<br/>


# Terraform Modules
<!-- BEGIN_TF_MAIN_DOCS -->
## main.tf
This is the core wrapper around all modules provided in this terraform and serves as an example of
how to run this terraform to build your Azure environment.

### Requirements

| Name | Version |
|------|---------|
| azapi | ~>1.5 |
| azurerm | ~>4.21.0 |
| http | ~>3.4.2 |
| null | >=3.2 |
| random | >=3.6.1 |
| time | >=0.9.1 |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_ssh\_pubkey | Your SSH public key for accessing resources via SSH | `string` | n/a | yes |
| admin\_username | Admin username for ssh access to resources. | `string` | `"lsroot"` | no |
| aks\_azure\_policy\_enabled | Enable the Azure Policy for AKS add-on allowing for security scanning of kubernetes resources. | `bool` | `"true"` | no |
| aks\_cost\_analysis\_enabled | Enable cost analysis for this AKS cluster? | `bool` | `"true"` | no |
| aks\_kubernetes\_version | Allows specification of the kubernetes version for AKS. Default of 'null' forces use of the latest recommended version at time of provisioning. | `string` | `null` | no |
| azure\_availability\_zones | The availability zones to use with your kubernetes cluster. Defaults to null making the cluster regional with no guarantee of HA in the event of zone outage. | `list` | `null` | no |
| azure\_environment | Azure cloud enviroment to use for your resources. Values include: public, usgovernment, german, and china. | `string` | `"public"` | no |
| azure\_keyvault\_secret\_expiration\_days | This ensures that secrets stored in Azure KeyVault expire after X number of days so they are not retained forever. This expiration date will update with every terraform run. | `number` | `60` | no |
| azure\_resource\_group\_region | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| azure\_subscription\_id | Subscription ID where you will build Azure resources. It is expected that you will be Owner of this subscription. | `string` | n/a | yes |
| azure\_vnet\_address\_space | Address space to assign to the virtual network that will resources associated to the kubernetes cluster. | `list` | <pre>[<br/>  "172.16.0.0/16"<br/>]</pre> | no |
| bastion\_host\_size | Size of virtual machine to launch for bastion host. | `string` | `"Standard_A2_v2"` | no |
| diag\_logging\_eventhub\_authorization\_rule\_id | The rule ID allowing authorization to the eventhub. | `string` | `null` | no |
| diag\_logging\_eventhub\_name | The target eventhub name where audit logging will be sent. Use in conjuction with the eventhub\_authorization\_rule\_id | `string` | `null` | no |
| diag\_logging\_loganalytics\_id | The ID of the log analytics workspace to send diagnostic logging. | `string` | `null` | no |
| diag\_logging\_storage\_account\_id | The target storage account id where audit logging will be sent. | `string` | `null` | no |
| enable\_auditlogging\_to\_eventhub | Enable audit logging to a target eventhub. | `bool` | `false` | no |
| enable\_auditlogging\_to\_loganalytics | Enable audit logging to a target log analytics workspace. | `bool` | `false` | no |
| enable\_auditlogging\_to\_storage | Enable audit logging to a target storage account | `bool` | `false` | no |
| enable\_azure\_ddos\_protection | Enable DDOS protection for the vnet created by this terraform. Note: DDOS protection will significantly increase the cost of this subscription. | `bool` | `false` | no |
| enable\_kv\_metrics\_diag\_logging | When sending diagnostic logs for the eventhub resource, we can optionally enable metrics as well. | `bool` | `false` | no |
| ip\_ranges\_allowed\_https | List of IP Ranges that can access the ingress frontend for UI and logscale API operations, including ingestion. | `list` | `[]` | no |
| ip\_ranges\_allowed\_kv\_access | List of IP Ranges that can access the key vault. | `list` | `[]` | no |
| ip\_ranges\_allowed\_storage\_account\_access | IP ranges allowed to access created storage containers | `list` | `[]` | no |
| ip\_ranges\_allowed\_to\_bastion | (Optional) List of IP addresses or CIDR notated ranges that can access the bastion host. | `list(string)` | `[]` | no |
| ip\_ranges\_allowed\_to\_kubeapi | IP ranges allowed to access the public kubernetes api | `list` | `[]` | no |
| k8s\_automatic\_upgrade\_channel | Upgrade channel for the kubernetes cluster. | `string` | `"patch"` | no |
| k8s\_general\_maintenance\_windows | This specifies when maintenance operations can be performed on the cluster and will take priority when more specific schedules are not set (i.e. maintenance\_window\_auto\_upgrade, maintenance\_window\_node\_os). | <pre>list(object({<br/>        day   = string<br/>        hours = list(number)<br/>    }))</pre> | <pre>[<br/>  {<br/>    "day": "Sunday",<br/>    "hours": [<br/>      2,<br/>      3,<br/>      4<br/>    ]<br/>  }<br/>]</pre> | no |
| k8s\_maintenance\_window\_auto\_upgrade | Allows for more granular control over AKS auto upgrades | <pre>object({<br/>    frequency    = string       # "Weekly", "RelativeMonthly"<br/>    interval     = number       # How often the schedule occurs (e.g., every 1 week/month)<br/>    duration     = number       # Length of maintenance window in hours<br/>    day_of_week  = string       # Required for Weekly frequency<br/>    utc_offset   = string       # e.g., "+00:00", "-07:00"<br/>    start_time   = string       # 24-hour format "HH:mm"<br/>    week_index   = optional(string) # Required when frequency is RelativeMonthly<br/>  })</pre> | `null` | no |
| k8s\_maintenance\_window\_node\_os | Sets a maintenance window for OS upgrades to AKS nodes. | <pre>object({<br/>    frequency    = string               # "Weekly", "RelativeMonthly"<br/>    interval     = number               # How often the schedule occurs (e.g., every 1 week/month)<br/>    duration     = number               # Length of maintenance window in hours<br/>    day_of_week  = string               # Required for Weekly / RelativeMonthly frequency<br/>    utc_offset   = string               # e.g., "+00:00", "-07:00"<br/>    start_time   = string               # 24-hour format "HH:mm"<br/>    week_index   = optional(string)     # Required when frequency is RelativeMonthly<br/>  })</pre> | `null` | no |
| k8s\_node\_os\_upgrade\_channel | Upgrade channel for the kubernetes nodes. | `string` | `"SecurityPatch"` | no |
| kubernetes\_private\_cluster\_enabled | When true, the kubernetes API is only accessible from internal networks (i.e. the bastion host). When false, the API is available to the list of IP ranges provided in variable ip\_ranges\_allowed\_to\_kubeapi. | `bool` | `false` | no |
| kv\_enabled\_for\_deployment | Allow virtual machines to retrieve certificates stored as secrets in the vault | `bool` | `true` | no |
| kv\_enabled\_for\_disk\_encryption | Allow azure disk encryption to retrieve and unwrap keys in the vault | `bool` | `true` | no |
| kv\_purge\_protection\_enabled | Enable purge protection for KV resources | `bool` | `true` | no |
| kv\_soft\_delete\_retention\_days | The number of days to retain items once soft-deleted. Values can be 7-90 | `number` | `7` | no |
| logscale\_account\_kind | The type of storage account to create. | `string` | `"StorageV2"` | no |
| logscale\_account\_replication | The type of replication to use with the logscale storage account. | `string` | `"LRS"` | no |
| logscale\_account\_tier | Storage account tier. | `string` | `"Standard"` | no |
| logscale\_cluster\_size | Size of the cluster to build in Azure. Reference cluster\_size.tpl for definitions. | `string` | `"xsmall"` | no |
| logscale\_cluster\_type | Logscale cluster type | `string` | n/a | yes |
| logscale\_lb\_internal\_only | The nginx ingress controller to logscale will create a managed azure load balancer with public availability. Setting to true will remove the ability to generate Let's Encrypt certificates in addition to removing public access. | `bool` | `false` | no |
| network\_subnet\_aks\_ingest\_nodes | A list of networks to associate to the ingress node subnet. | `list` | <pre>[<br/>  "172.16.5.0/24"<br/>]</pre> | no |
| network\_subnet\_aks\_ingress\_nodes | A list of networks to associate to the ingress node subnet. | `list` | <pre>[<br/>  "172.16.4.0/24"<br/>]</pre> | no |
| network\_subnet\_aks\_logscale\_digest\_nodes | Subnet for the kubernetes node pool hosting logscale digest nodes. | `list` | <pre>[<br/>  "172.16.3.0/24"<br/>]</pre> | no |
| network\_subnet\_aks\_system\_nodes | Subnet for kubernetes system nodes. In the basic architecture, this will also be where nginx ingress nodes are placed. | `list` | <pre>[<br/>  "172.16.0.0/24"<br/>]</pre> | no |
| network\_subnet\_aks\_ui\_nodes | A list of networks to associate to the ingress node subnet. | `list` | <pre>[<br/>  "172.16.6.0/24"<br/>]</pre> | no |
| network\_subnet\_bastion\_nodes | Subnet for bastion nodes. | `list` | <pre>[<br/>  "172.16.1.0/26"<br/>]</pre> | no |
| network\_subnet\_kafka\_nodes | Subnet for kubernetes node pool hosting the strimzi kafka nodes | `list` | <pre>[<br/>  "172.16.2.0/24"<br/>]</pre> | no |
| provision\_kafka\_servers | Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation. | `bool` | `true` | no |
| resource\_name\_prefix | Identifier attached to named resources to help them stand out. Must be 8 or fewer characters which can include lower case, numbers, and hyphens. | `string` | `"log"` | no |
| set\_kv\_expiration\_dates | Setting expiration dates on vault secrets will help ensure that secrets are not retained forever but it's not always feasible to have static expiration dates. Set this to false to disable expirations. | `bool` | `true` | no |
| tags | A map of tags to apply to all created resources. | `map` | `{}` | no |
| use\_own\_certificate\_for\_ingress | Set to true if you plan to bring your own certificate for logscale ingest/ui access. | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| AZURE\_STORAGE\_ACCOUNTNAME | n/a |
| AZURE\_STORAGE\_BUCKET | n/a |
| AZURE\_STORAGE\_ENDPOINT\_BASE | n/a |
| AZURE\_STORAGE\_OBJECT\_KEY\_PREFIX | Prefix added to resources for unique identification |
| azure-dns-label-name | n/a |
| azure-load-balancer-resource-group | n/a |
| azure-pip-name | n/a |
| controller\_service\_loadBalancerIP | Public IP address for access to logscale environment via Azure LB, when public access is enabled |
| k8s\_cluster\_context | Kubernetes information |
| k8s\_cluster\_name | n/a |
| k8s\_configuration\_command | Run this command after building the kubernetes cluster to set your local kube config |
| logscale\_cluster\_size | n/a |
| logscale\_cluster\_type | n/a |
| logscale\_public\_fqdn | Public FQDN for access to logscale environment via Azure LB, when public access is enabled |

<!-- END_TF_MAIN_DOCS -->

<!-- BEGIN_AZCORE_MAIN_DOCS -->
## Module: azure/core
This module provisions all core requirements for the Azure infrastructure including:
* Azure Virtual Network
* Azure Subnets
* Optional Enablement of DDOS Protection Plan
* NAT Gateway with Public IP
* Public IP and FQDN for Ingress (when public access is enabled)

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bastion\_network\_subnet | A list of networks to associate to the bastion host subnet. | `list` | n/a | yes |
| enable\_azure\_ddos\_protection | Enable Azure DDOS Protection | `bool` | n/a | yes |
| enabled\_logscale\_digest\_service\_endpoints | List of service endpoints required for the subnet. Storage is required for vnet-only access. | `list` | <pre>[<br/>  "Microsoft.Storage"<br/>]</pre> | no |
| environment | Azure cloud enviroment to use for your resources. Values include: public, usgovernment, german, and china. | `string` | n/a | yes |
| logscale\_cluster\_type | Type of cluster being built. | `string` | n/a | yes |
| logscale\_lb\_internal\_only | The nginx ingress controller to logscale will create a managed azure load balancer with public availability. In this core module, this variable determines if the public IP address for this load balancer needs to be created. | `bool` | `false` | no |
| name\_prefix | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| network\_subnet\_aks\_logscale\_digest\_nodes | A list of networks to associate to the kubernetes subnet. | `list` | n/a | yes |
| network\_subnet\_aks\_system\_nodes | A list of networks to associate to the kubernetes subnet. | `list` | n/a | yes |
| network\_subnet\_ingest\_nodes | A list of networks to associate to the ingest node subnet. | `list` | n/a | yes |
| network\_subnet\_ingress\_nodes | A list of networks to associate to the ingress node subnet. | `list` | n/a | yes |
| network\_subnet\_kafka\_nodes | A list of networks to associate to the kafka subnet. | `list` | n/a | yes |
| network\_subnet\_ui\_nodes | A list of networks to associate to the ui node subnet. | `list` | n/a | yes |
| provision\_kafka\_servers | Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation. | `bool` | `true` | no |
| resource\_group\_region | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| subscription\_id | Subscription ID for your Azure resources. | `string` | n/a | yes |
| tags | A map of tags to apply to all created resources. | `map` | n/a | yes |
| vnet\_address\_space | Address space to assign to the virtual network that will resources associated to the kubernetes cluster. | `list` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| bastion\_subnet\_id | n/a |
| ingress-pub-fqdn | FQDN for logscale ingress when using a public endpoint. |
| ingress-pub-ip | IP Address for logscale ingress when using a public endpoint. |
| ingress-pub-pip-name | n/a |
| ingress-pup-pip-domain-name-label | n/a |
| kafka\_nodes\_subnet\_id | n/a |
| logscale\_digest\_nodes\_subnet\_id | n/a |
| logscale\_ingest\_nodes\_subnet\_id | n/a |
| logscale\_ingress\_nodes\_subnet\_id | n/a |
| logscale\_ui\_nodes\_subnet\_id | n/a |
| nat\_gw\_public\_ip | NAT GW IP address for your subnets which can be used to allow access as necessary to other environments. |
| resource\_group\_id | n/a |
| resource\_group\_name | Azure Resource Group |
| resource\_group\_region | n/a |
| system\_nodes\_subnet\_id | n/a |
| vnet\_id | n/a |
| vnet\_name | n/a |

<!-- END_AZCORE_MAIN_DOCS -->

<!-- BEGIN_AZAKS_MAIN_DOCS -->
## Module: azure/aks
This module provisions managed Azure Kubernetes within the environment.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_ssh\_pubkey | Public key for SSH access to the bastion host. | `string` | n/a | yes |
| admin\_username | Admin username for ssh access to k8s nodes. | `string` | n/a | yes |
| aks\_system\_nodes\_subnet\_id | Subnet ID for AKS system nodes to live in. | `any` | n/a | yes |
| authorized\_ip\_ranges | IP Ranges allowed to access the public kubernetes API | `list` | `[]` | no |
| azure\_availability\_zones | The availability zones to use with your kubernetes cluster. Defaults to null making the cluster regional with no guarantee of HA in the event of zone outage. | `list` | `null` | no |
| azure\_keyvault\_id | Azure KeyVault id used for storing secrets related to this infrastructure | `string` | n/a | yes |
| azure\_keyvault\_secret\_expiration\_date | When secrets should expire. | `string` | n/a | yes |
| azure\_policy\_enabled | Enable the Azure Policy for AKS add-on? | `bool` | n/a | yes |
| cost\_analysis\_enabled | Enable cost analysis for this AKS cluster? | `bool` | n/a | yes |
| diag\_logging\_eventhub\_authorization\_rule\_id | The rule ID allowing authorization to the eventhub. | `string` | `null` | no |
| diag\_logging\_eventhub\_name | The target eventhub name where audit logging will be sent. Use in conjuction with the eventhub\_authorization\_rule\_id | `string` | `null` | no |
| diag\_logging\_loganalytics\_id | The ID of the log analytics workspace to send diagnostic logging. | `string` | `null` | no |
| diag\_logging\_storage\_account\_id | The target storage account id where audit logging will be sent. | `string` | `null` | no |
| disk\_encryption\_key\_expiration\_date | Optionally set when the disk encryption key used for AKS nodes should expire. Defaults to null on the assumption that this AKS cluster might be long-lived. | `string` | `null` | no |
| enable\_auditlogging\_to\_eventhub | Enable audit logging to a target eventhub. | `bool` | `false` | no |
| enable\_auditlogging\_to\_loganalytics | Enable audit logging to a target log analytics workspace. | `bool` | `false` | no |
| enable\_auditlogging\_to\_storage | Enable audit logging to a target storage account | `bool` | `false` | no |
| enable\_kv\_metrics\_diag\_logging | When sending diagnostic logs for the eventhub resource, we can optionally enable metrics as well. | `bool` | `false` | no |
| environment | Azure cloud enviroment to use for your resources. | `string` | n/a | yes |
| ip\_ranges\_allowed\_https | IP Ranges allowed to access the nginx-ingress loadbalancer pods | `list` | `[]` | no |
| k8s\_automatic\_upgrade\_channel | Upgrade channel for the kubernetes cluster. | `string` | `"patch"` | no |
| k8s\_general\_maintenance\_windows | This specifies when maintenance operations can be performed on the cluster and will take priority when more specific schedules are not set (i.e. maintenance\_window\_auto\_upgrade, maintenance\_window\_node\_os). | <pre>list(object({<br/>        day   = string<br/>        hours = list(number)<br/>    }))</pre> | <pre>[<br/>  {<br/>    "day": "Sunday",<br/>    "hours": [<br/>      2,<br/>      3,<br/>      4<br/>    ]<br/>  }<br/>]</pre> | no |
| k8s\_maintenance\_window\_auto\_upgrade | Allows for more granular control over AKS auto upgrades | <pre>object({<br/>    frequency    = string       # "Weekly", "RelativeMonthly"<br/>    interval     = number       # How often the schedule occurs (e.g., every 1 week/month)<br/>    duration     = number       # Length of maintenance window in hours<br/>    day_of_week  = string       # Required for Weekly frequency<br/>    utc_offset   = string       # e.g., "+00:00", "-07:00"<br/>    start_time   = string       # 24-hour format "HH:mm"<br/>    week_index   = optional(string) # Required when frequency is RelativeMonthly<br/>  })</pre> | `null` | no |
| k8s\_maintenance\_window\_node\_os | Sets a maintenance window for OS upgrades to AKS nodes. | <pre>object({<br/>    frequency    = string               # "Weekly", "RelativeMonthly"<br/>    interval     = number               # How often the schedule occurs (e.g., every 1 week/month)<br/>    duration     = number               # Length of maintenance window in hours<br/>    day_of_week  = string               # Required for Weekly / RelativeMonthly frequency<br/>    utc_offset   = string               # e.g., "+00:00", "-07:00"<br/>    start_time   = string               # 24-hour format "HH:mm"<br/>    week_index   = optional(string)     # Required when frequency is RelativeMonthly<br/>  })</pre> | `null` | no |
| k8s\_node\_os\_upgrade\_channel | Upgrade channel for the kubernetes nodes. | `string` | `"SecurityPatch"` | no |
| kafka\_nodes\_subnet\_id | Subnet ID where kafka nodes will live. | `string` | n/a | yes |
| kubernetes\_diagnostic\_log\_categories | List of enabled diagnostic log categories for the kubernetes cluster. | `list` | <pre>[<br/>  "kube-apiserver",<br/>  "kube-controller-manager",<br/>  "kube-scheduler",<br/>  "kube-audit",<br/>  "kube-audit-admin"<br/>]</pre> | no |
| kubernetes\_version | Allows specification of the kubernetes version for AKS. Default of 'null' forces use of the latest recommended version at time of provisioning. | `string` | `null` | no |
| logscale\_cluster\_type | Logscale cluster type | `string` | n/a | yes |
| logscale\_digest\_nodes\_subnet\_id | Subnet ID for logscale digest nodes. | `any` | n/a | yes |
| logscale\_ingest\_node\_desired\_count | n/a | `number` | n/a | yes |
| logscale\_ingest\_node\_max\_count | n/a | `number` | n/a | yes |
| logscale\_ingest\_node\_min\_count | n/a | `number` | n/a | yes |
| logscale\_ingest\_nodes\_subnet\_id | Subnet ID for ingest nodes. | `any` | n/a | yes |
| logscale\_ingest\_os\_disk\_size | n/a | `number` | n/a | yes |
| logscale\_ingest\_vmsize | n/a | `string` | n/a | yes |
| logscale\_ingress\_node\_desired\_count | n/a | `number` | n/a | yes |
| logscale\_ingress\_node\_max\_count | n/a | `number` | n/a | yes |
| logscale\_ingress\_node\_min\_count | n/a | `number` | n/a | yes |
| logscale\_ingress\_nodes\_subnet\_id | Subnet ID for ingest nodes. | `any` | n/a | yes |
| logscale\_ingress\_os\_disk\_size | n/a | `number` | n/a | yes |
| logscale\_ingress\_vmsize | n/a | `string` | n/a | yes |
| logscale\_node\_desired\_count | n/a | `number` | n/a | yes |
| logscale\_node\_max\_count | n/a | `number` | n/a | yes |
| logscale\_node\_min\_count | n/a | `number` | n/a | yes |
| logscale\_node\_os\_disk\_size\_gb | n/a | `number` | n/a | yes |
| logscale\_node\_vmsize | n/a | `string` | n/a | yes |
| logscale\_ui\_node\_desired\_count | n/a | `number` | n/a | yes |
| logscale\_ui\_node\_max\_count | n/a | `number` | n/a | yes |
| logscale\_ui\_node\_min\_count | n/a | `number` | n/a | yes |
| logscale\_ui\_nodes\_subnet\_id | Subnet ID for ingest nodes. | `any` | n/a | yes |
| logscale\_ui\_os\_disk\_size | n/a | `number` | n/a | yes |
| logscale\_ui\_vmsize | n/a | `string` | n/a | yes |
| name\_prefix | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| private\_cluster\_enabled | Should the kubernetes API be private only? Setting to private has implications to how to run this IaaC. Refer to documentation for more detail. | `bool` | n/a | yes |
| provision\_kafka\_servers | Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation. | `bool` | `true` | no |
| resource\_group\_id | The ID of the resource group where the kubernetes managed identity will be granted network contributor access. | `string` | n/a | yes |
| resource\_group\_name | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| resource\_group\_region | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| sku\_tier | Tier for the AKS cluster, Standard or Premium | `string` | `"Standard"` | no |
| strimzi\_node\_desired\_count | n/a | `number` | n/a | yes |
| strimzi\_node\_instance\_type | n/a | `string` | n/a | yes |
| strimzi\_node\_max\_count | n/a | `number` | n/a | yes |
| strimzi\_node\_min\_count | n/a | `number` | n/a | yes |
| strimzi\_node\_os\_disk\_size\_gb | n/a | `number` | n/a | yes |
| subscription\_id | Subscription ID for your Azure resources. | `string` | n/a | yes |
| system\_node\_desired\_count | n/a | `number` | n/a | yes |
| system\_node\_max\_count | n/a | `number` | n/a | yes |
| system\_node\_min\_count | n/a | `number` | n/a | yes |
| system\_node\_os\_disk\_size\_gb | n/a | `number` | n/a | yes |
| system\_node\_vmsize | n/a | `string` | n/a | yes |
| tags | A map of tags to apply to all created resources. | `map` | n/a | yes |
| use\_custom\_certificate | Use a custom provided certificate for ingress. In this module, this setting controls creation of a NSG rule that allows for Let's Encrypt ACME challenges. | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| k8s\_client\_certificate\_kv\_name | n/a |
| k8s\_client\_key\_kv\_name | n/a |
| k8s\_cluster\_ca\_certificate\_kv\_name | n/a |
| k8s\_cluster\_endpoint | n/a |
| k8s\_cluster\_id | n/a |
| k8s\_cluster\_name | n/a |
| k8s\_cluster\_principal\_id | Kubernetes information |
| k8s\_kube\_config\_kv\_name | n/a |

<!-- END_AZAKS_MAIN_DOCS -->

<!-- BEGIN_AZBAS_MAIN_DOCS -->
## Module: azure/bastion
An optional module that can be used to provision a bastion host. This is particularly useful when provisioning a brand new
environment and setting the kubernetes API to private access only.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_ssh\_pubkey | Public key for SSH access to the bastion host. | `string` | n/a | yes |
| admin\_username | Admin username for ssh access to k8s nodes. | `string` | n/a | yes |
| bastion\_host\_size | Sizing for the bastion host. | `string` | n/a | yes |
| bastion\_subnet\_id | Subnet ID to attach the bastion host NIC. | `string` | n/a | yes |
| environment | Azure cloud enviroment to use for your resources. | `string` | n/a | yes |
| ip\_ranges\_allowed | List of IP addresses or CIDR notated ranges that can access the bastion host. | `list` | n/a | yes |
| name\_prefix | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| resource\_group\_name | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| resource\_group\_region | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| subscription\_id | Subscription ID for your Azure resources. | `string` | n/a | yes |
| tags | A map of tags to apply to all created resources. | `map` | n/a | yes |
| vnet\_name | Name of the virtual network where this resource will live | `string` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| bastion\_host\_private\_ip | n/a |
| bastion\_nsg\_name | n/a |
| bastion\_public\_dns\_name | n/a |
| bastion\_public\_ip\_address | Bastion Host Connection Information |

<!-- END_AZBAS_MAIN_DOCS -->

<!-- BEGIN_AZCERT_MAIN_DOCS -->
## Module: azure/certificate
An optional module that can be used to provision a certificate within Azure KeyVault. This is expected to be used for self-signed
test certificates but depending on the configuration of your KeyVault, it can be leveraged to provsion valid certs.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azure\_keyvault\_id | The Azure Keyvault ID storing all the secrets above. | `string` | n/a | yes |
| cert\_issuer | The issuer to use for certificate generation. Defaults to Self but can match any issuer registered in your environment. | `string` | `"Self"` | no |
| logscale\_public\_fqdn | The FQDN tied to the public IP address for logscale ingress. This is the resource that will have a certificate provisioned from let's encrypt. | `string` | n/a | yes |
| name\_prefix | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| subject\_alternative\_names | List of alternative names for the certificate. | `list` | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| certificate\_keyvault\_name | n/a |

<!-- END_AZCERT_MAIN_DOCS -->

<!-- BEGIN_AZIDENT_MAIN_DOCS -->
## Module: azure/identity
This optional module can be used to provision a managed identity in Azure and assign a role to the identity.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name\_prefix | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| resource\_group\_name | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| resource\_group\_region | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| role\_definition\_name | Built-in role definition to assign to the created identity | `string` | `"Storage Blob Data Owner"` | no |
| tags | A map of tags to apply to all created resources. | `map` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| managed\_identity\_resource\_id | n/a |
| managed\_identity\_resource\_principal\_id | n/a |

<!-- END_AZIDENT_MAIN_DOCS -->

<!-- BEGIN_AZKV_MAIN_DOCS -->
## Module: azure/keyvault
This module provisions an Azure Keyvault for storing sensititve environment secrets for use across terraform modules.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| certificate\_permissions | The keyvault will be created with an access policy that grants permission to the calling user to do most things for the purposes of this terraform run. These permissions can be adjusted as required. | `list` | <pre>[<br/>  "Create",<br/>  "Delete",<br/>  "Get",<br/>  "GetIssuers",<br/>  "Import",<br/>  "List",<br/>  "ListIssuers",<br/>  "Update"<br/>]</pre> | no |
| diag\_logging\_eventhub\_authorization\_rule\_id | The rule ID allowing authorization to the eventhub. | `string` | `null` | no |
| diag\_logging\_eventhub\_name | The target eventhub name where audit logging for the keyvault will be sent. Use in conjuction with the eventhub\_authorization\_rule\_id | `string` | `null` | no |
| diag\_logging\_loganalytics\_id | The ID of the log analytics workspace to send diagnostic logging. | `string` | `null` | no |
| diag\_logging\_storage\_account\_id | The target storage account id where audit logging for the keyvault will be sent. | `string` | `null` | no |
| enable\_auditlogging\_to\_eventhub | Enable audit logging to a target eventhub. | `bool` | `false` | no |
| enable\_auditlogging\_to\_loganalytics | Enable audit logging to a target log analytics workspace. | `bool` | `false` | no |
| enable\_auditlogging\_to\_storage | Enable audit logging to a target storage account | `bool` | `false` | no |
| enable\_kv\_metrics\_diag\_logging | When sending diagnostic logs for the eventhub resource, we can optionally enable metrics as well. | `bool` | `false` | no |
| enabled\_for\_deployment | Allow virtual machines to retrieve certificates stored as secrets in the vault | `bool` | `true` | no |
| enabled\_for\_disk\_encryption | Allow azure disk encryption to retrieve and unwrap keys in the vault | `bool` | `true` | no |
| ip\_ranges\_allowed\_kv\_access | IP Ranges allowed access to keyvault outside of trusted AzureServices. | `list` | `[]` | no |
| key\_permissions | The keyvault will be created with an access policy that grants permission to the calling user to do most things for the purposes of this terraform run. These permissions can be adjusted as required. | `list` | <pre>[<br/>  "Get",<br/>  "List",<br/>  "Update",<br/>  "Delete",<br/>  "Encrypt",<br/>  "Decrypt",<br/>  "WrapKey",<br/>  "UnwrapKey",<br/>  "Create",<br/>  "GetRotationPolicy",<br/>  "SetRotationPolicy",<br/>  "Recover",<br/>  "Purge",<br/>  "Backup"<br/>]</pre> | no |
| name\_prefix | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| purge\_protection\_enabled | Enable purge protection for KV resources | `bool` | `true` | no |
| resource\_group\_name | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| resource\_group\_region | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| secret\_permissions | The keyvault will be created with an access policy that grants permission to the calling user to do most things for the purposes of this terraform run. These permissions can be adjusted as required. | `list` | <pre>[<br/>  "Get",<br/>  "List",<br/>  "Set",<br/>  "Delete",<br/>  "Recover"<br/>]</pre> | no |
| sku\_name | Standard or Premium SKU for the key vault. | `string` | `"standard"` | no |
| soft\_delete\_retention\_days | The number of days to retain items once soft-deleted. Values can be 7-90 | `number` | `7` | no |
| tags | A map of tags to apply to all created resources. | `map` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| keyvault\_id | n/a |
| keyvault\_name | n/a |

<!-- END_AZKV_MAIN_DOCS -->

<!-- BEGIN_AZSTOR_MAIN_DOCS -->
## Module: azure/storage
This module provisions a storage account and optional container designed for provisioning storage for Logscale Object storage.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azure\_keyvault\_id | Azure KeyVault id used for storing secrets related to this infrastructure | `string` | n/a | yes |
| azure\_keyvault\_secret\_expiration\_date | When secrets should expire. | `string` | n/a | yes |
| create\_container | n/a | `bool` | `false` | no |
| diag\_logging\_eventhub\_authorization\_rule\_id | The rule ID allowing authorization to the eventhub. | `string` | `null` | no |
| diag\_logging\_eventhub\_name | The target eventhub name where audit logging will be sent. Use in conjuction with the eventhub\_authorization\_rule\_id | `string` | `null` | no |
| diag\_logging\_loganalytics\_id | The ID of the log analytics workspace to send diagnostic logging. | `string` | `null` | no |
| diag\_logging\_storage\_account\_id | The target storage account id where audit logging will be sent. | `string` | `null` | no |
| enable\_auditlogging\_to\_eventhub | Enable audit logging to a target eventhub. | `bool` | `false` | no |
| enable\_auditlogging\_to\_loganalytics | Enable audit logging to a target log analytics workspace. | `bool` | `false` | no |
| enable\_auditlogging\_to\_storage | Enable audit logging to a target storage account | `bool` | `false` | no |
| enable\_hns | n/a | `bool` | `true` | no |
| ip\_ranges\_allowed\_storage\_account\_access | IP Ranges allowed access to the storage account | `list` | `[]` | no |
| min\_tls\_version | Minimum TLS version accepted by the storage container. | `string` | `"TLS1_2"` | no |
| name\_prefix | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| resource\_group\_name | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| resource\_group\_region | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| shared\_access\_key\_enabled | Allow shared access keys to the storage containers. Defaults to true, as of Logscale 1.174, this method of access is required. | `bool` | `true` | no |
| storage\_access\_default\_action | By default, allow or deny access to the storage account | `string` | `"Deny"` | no |
| storage\_account\_blob\_log\_categories | List of enabled diagnostic log categories for the storage account. | `list` | <pre>[<br/>  "StorageRead",<br/>  "StorageWrite",<br/>  "StorageDelete"<br/>]</pre> | no |
| storage\_account\_file\_log\_categories | List of enabled diagnostic log categories for the storage account. | `list` | <pre>[<br/>  "StorageRead",<br/>  "StorageWrite",<br/>  "StorageDelete"<br/>]</pre> | no |
| storage\_account\_kind | n/a | `string` | `"StorageV2"` | no |
| storage\_account\_queue\_log\_categories | List of enabled diagnostic log categories for the storage account. | `list` | <pre>[<br/>  "StorageRead",<br/>  "StorageWrite",<br/>  "StorageDelete"<br/>]</pre> | no |
| storage\_account\_replication | n/a | `string` | `"LRS"` | no |
| storage\_account\_table\_log\_categories | List of enabled diagnostic log categories for the storage account. | `list` | <pre>[<br/>  "StorageRead",<br/>  "StorageWrite",<br/>  "StorageDelete"<br/>]</pre> | no |
| storage\_account\_tier | Storage account tier. | `string` | `"Standard"` | no |
| storage\_network\_rules\_bypass | Defines traffic that can bypass the network-based restrictions applied. Can be a list containing: Metrics, Logging, and/or AzureServices. Can also be set to: None | `list` | <pre>[<br/>  "AzureServices",<br/>  "Metrics",<br/>  "Logging"<br/>]</pre> | no |
| tags | A map of tags to apply to all created resources. | `map` | n/a | yes |
| vnet\_subnets\_allowed\_storage\_account\_access | List of subnet ids in the vnet allowed access to the storage account | `list` | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| storage\_acct\_access\_key\_kv | n/a |
| storage\_acct\_blob\_endpoint | n/a |
| storage\_acct\_container\_id | n/a |
| storage\_acct\_container\_name | n/a |
| storage\_acct\_id | n/a |
| storage\_acct\_name | n/a |

<!-- END_AZSTOR_MAIN_DOCS -->

