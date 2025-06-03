[![CrowdStrike Falcon](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)]((https://www.crowdstrike.com/)) [![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)<br/>
# Contents
1. [Introduction](#logscale-reference-automations-for-azure)
2. [Requirements and Build Information](#requirements-and-build-information)
    - [Azure Access Requirements](#azure-access-requirements)
    - [IP-Based Access Restrictions](#ip-based-access-restrictions)
    - [Kubernetes Namespace Separation](#kubernetes-namespace-separation)
    - [Cluster Size Configuration](#cluster-size-configuration)
    - [Setting Logscale Configuration](#setting-logscale-configuration-variables)
    - [Bring Your Own Kafka](#bring-your-own-kafka)
    - [Bring Your Own Certificate](#bring-your-own-certificate)
    - [Targeted Terraform Application](#targeted-terraform)
3. [Terraform Modules](#terraform-modules)
4. [Build Process](#build-process)
5. [Support](#support)
6. [References](#references)


# LogScale Reference Automations for Azure
This repository contains Terraform configurations to deploy an Azure-based architecture for LogScale. It leverages multiple Azure services including Azure Key Vault, Azure Kubernetes Service, and Azure Storage.

# Requirements and Build Information
## Prerequisites
Before starting the deployment, ensure you have the following tools and access:

- **Terraform 1.10.5**: Terraform is the infrastructure as code tool used to manage the deployment. Version 1.10.5 is recommended at this time due to known issues in 1.11.0/1.11.1.
- **kubectl 1.232+**: kubectl is the command-line tool for interacting with the Kubernetes cluster.
- **Azure Command Line 2.68.0+**: The Azure Command Line (az cli) allows you to interact with Azure services from the command line.
- **Owner Access to Azure Subscription**: For full architecture deployment, owner access is expected to the target Azure subscription.

It is additionally recommended but not required to install Helm 3.17.0 or later for troubleshooting helm-based kubernetes deployments.

### Azure Access Requirements
The account running this Terraform needs to be assigned the Owner role for the target subscription due to the assignment of roles to the managed identity used by the kubernetes control plane. Role assignment for the Kubernetes cluster is as follows:

- **Reader** scoped to the Disk Encryption Set created during this process
    - Allows identity to read the disk encryption set used for node disk encryption
- **Network Contributor** scoped to the resource group created by this terraform
    - Allows identity to bind a managed load balancer to a public IP created during the Terraform run for environment access
- **Key Vault Crypto User** scoped to the Azure Key Vault created during this process
    - Allows the disk set encryption managed identity the ability to use the key vault for disk encryption

### IP-based Access Restrictions
There are four variables that control public access to the environment and set in your `TFVAR_FILE` configuration.
```
ip_ranges_allowed_to_kubeapi            = ["192.168.3.32/32", "192.168.4.1/32"]
ip_ranges_allowed_https                 = ["192.168.1.0/24"]
ip_ranges_allowed_to_bastion            = ["192.168.3.32/32", "192.168.4.1/32"]
ip_ranges_allowed_kv_access             = ["192.168.3.32/32", "192.168.4.1/32"]
```

- **ip_ranges_allowed_to_kubeapi** : The Kubernetes API is publicly available by default. This variable limits access to the API and impacts the ability to run Kubernetes API commands.
- **ip_ranges_allowed_https** : The ingress endpoint for UI Access to Logscale and Ingestion to logscale is publicly available. This limits access.
- **ip_ranges_allowed_to_bastion** : If you choose to build a bastion host during this process, this limits access to SSH to the host.
- **ip_ranges_allowed_kv_access** : Access to the Azure Key Vault is limited to ranges defined here.

**Note:** `ip_ranges_allowed_kv_access` and `ip_ranges_allowed_to_kubeapi` must be set correctly for Terraform to operate as expected.

## Kubernetes Namespace Separation
Multiple namespaces are created in Kubernetes during the terraform application process in order to promote security and separation of the applications. All namespaces are created using variable `var.k8s_namespace_prefix` (default: **log**). Assuming the default value for k8s_namespace_prefix, terraform creates the following namespaces in kubernetes:

- log
    - Logscale
    - Humio Operator
    - Strimzi Kafka Brokers / Controllers **(Optional)**
    - Strimzi Kafka Operator **(Optional)**
- log-topolvm
    - TopoLVM Controller and Nodes
- log-cert
    - Cert Manager
- log-ingress
    - NGINX ingress controllers

## Cluster Size Configuration
The `cluster_size.tpl` file specifies the available parameters for different sizes of LogScale clusters. This template defines various cluster sizes (e.g., xsmall, small, medium) and their associated configurations, including node counts, instance types, disk sizes, and resource limits. The Terraform configuration uses this template to dynamically configure the LogScale deployment based on the selected cluster size.

- **File:** `cluster_size.tpl`
- **Usage:**
  The data from `cluster_size.tpl` is retrieved and rendered by the `locals.tf` file. The `locals.tf` file uses the `jsondecode` function to parse the template and select the appropriate cluster size configuration based on the `logscale_cluster_size` variable.

- **Example:**
```hcl
  # Local Variables
  locals {
    # Render a template of available cluster sizes
    cluster_size_template = jsondecode(templatefile("${path.module}/cluster_size.tpl", {}))
    cluster_size_rendered = {
      for key in keys(local.cluster_size_template) :
      key => local.cluster_size_template[key]
    }
    cluster_size_selected = local.cluster_size_rendered[var.logscale_cluster_size]
  }
```

## Setting Logscale Configuration Variables
Logscale will be configured with a default set of configuration values that can be overridden or added to by defining `var.user_logscale_envars` in your `TFVAR_FILE`. For example, to change default values for `LOCAL_STORAGE_MIN_AGE_DAYS` and `LOCAL_STORAGE_PERCENTAGE`, you can set this in your `TFVAR_FILE`:

```json
    user_logscale_envvars = [ { "name" = "LOCAL_STORAGE_MIN_AGE_DAYS", "value" = "7" }, { "name" = "LOCAL_STORAGE_PERCENTAGE", "value" = "85" } ]
```

This mechanism also supports referencing Kubernetes secrets should you provision them outside this Terraform:

```json
    user_logscale_envvars = [
        {
        "name" = "SECRET_LOGSCALE_CONFIGURATION",
        "valueFrom" = {
            "secretKeyRef" = {
                "key"  = "secret_value"
                "name" = "kubernetes_secret_name"
            }
        }
        },
        { "name" = "LOCAL_STORAGE_MIN_AGE_DAYS", "value" = "7" },
        { "name" = "LOCAL_STORAGE_PERCENTAGE", "value" = "85" }
    ]
```

The default environment values set by this Terraform are as follows:

| Configuration Name | Value |
| ------------------ | ----- |
| AZURE_BUCKET_STORAGE_ENABLED | true |
| AZURE_STORAGE_USE_HTTP_PROXY | false |
| AZURE_STORAGE_ACCOUNTNAME | `var.azure_storage_account_name` |
| AZURE_STORAGE_BUCKET | `var.azure_storage_container_name` |
| AZURE_STORAGE_ENDPOINT_BASE | `var.azure_storage_endpoint_base` |
| AZURE_STORAGE_OBJECT_KEY_PREFIX | `var.name_prefix` |
| AZURE_STORAGE_REGION | `var.azure_storage_region` |
| AZURE_STORAGE_ACCOUNTKEY | Kubernetes Secret: `var.k8s_secret_storage_access_key` |
| AZURE_STORAGE_ENCRYPTION_KEY | Kubernetes Secret: `var.k8s_secret_encryption_key` |
| KAFKA_COMMON_SECURITY_PROTOCOL | SSL |
| USING_EPHEMERAL_DISKS | true |
| LOCAL_STORAGE_PERCENTAGE | 80 |
| LOCAL_STORAGE_MIN_AGE_DAYS | 1 |
| KAFKA_BOOTSTRAP_SERVERS | `var.kafka_broker_servers` |
| KAFKA_SERVERS | `var.kafka_broker_servers` |
| PUBLIC_URL | `https://${var.logscale_public_fqdn}` |
| AUTHENTICATION_METHOD | static |
| STATIC_USERS | Kubernetes Secret: `var.k8s_secret_static_user_logins` |
| KAFKA_COMMON_SSL_TRUSTSTORE_TYPE * | PKCS12 |
| KAFKA_COMMON_SSL_TRUSTSTORE_PASSWORD * | Kubernetes Secret: `local.kafka_truststore_secret_name` |
| KAFKA_COMMON_SSL_TRUSTSTORE_LOCATION * | /tmp/kafka/ca.p12 |

Values marked with * are removed when `var.provision_kafka_servers` is set to false.

## Bring Your Own Kafka
If Kafka already exists and meets the following expectations, it can be used in place of Strimzi created by this Terraform. Expected configuration:
1. Client Authentication: None (TBD)
2. KRaft Mode: Enabled
3. TLS Communications: Enabled

In order to use your own Kafka, make the following modifications to the execution instructions:

1. Set terraform variable `provision_kafka_servers` to false
2. Set terraform variable `byo_kafka_connection_string` to your connection string.
3. Do not execute the build of Strimzi in the following instructions

## Bring Your Own Certificate
By default, a Let's Encrypt certificate will be generated and placed on the ingress controller. You can bring your own certificate to the ingress by:

1. Importing or generating a certificate in Azure Keyvault. Reference: [Azure Key Vault Certificate Import](https://learn.microsoft.com/en-us/azure/key-vault/certificates/tutorial-import-certificate)
2. Passing this information to module logscale in main.tf
```hcl
    module "logscale" {
    source                                        = "./modules/kubernetes/logscale"
    <truncated for readability>
    
    use_custom_certificate                        = true
    custom_tls_certificate_keyvault_entry         = "my-keyvault-item-name"
    
    <truncated for readability>
    }
```

A module exists in this Terraform that allows for provisioning a certificate via Azure Key Vault. This is self-signed by default but the module allows for alternative certificate issuers depending on your environment.

```hcl
    module "azure-selfsigned-cert" {
    source                                        = "./modules/azure/certificate"
    azure_keyvault_id                             = module.azure-keyvault.keyvault_id
    logscale_public_fqdn                          = "this-is-a-test.local"
    name_prefix                                   = local.resource_name_prefix
    subject_alternative_names                     = [module.azure-core.ingress-pub-fqdn, "othername.local"]  
    cert_issuer                                   = "Self"    
    }
```

## Targeted Terraform
When leveraging this Terraform repository, you must run terraform using the -target flag to apply specific modules. The latter half of the terraforming process requires access to a kubernetes API to successfully plan and apply changes. 

After the environment is fully built, the targeted approach isn't strictly required but remains recommended to ensure proper order of operations.

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
| helm | >=2.13.2 |
| http | ~>3.4.2 |
| kubernetes | >=2.31.0 |
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
| byo\_kafka\_connection\_string | Your own kafka environment connection string. | `string` | `""` | no |
| cert\_ca\_server | Certificate Authority Server. | `string` | `"https://acme-v02.api.letsencrypt.org/directory"` | no |
| cert\_issuer\_email | Certificates issuer email address used with certificates provisioned in the cluster. | `string` | n/a | yes |
| cert\_issuer\_kind | Certificates issuer kind for the Logscale cluster. | `string` | `"ClusterIssuer"` | no |
| cert\_issuer\_name | Certificates issuer name for the Logscale Cluster | `string` | `"letsencrypt-cluster-issuer"` | no |
| cert\_issuer\_private\_key | This is the kubernetes secret where the private key for the certificate issuer will be stored. | `string` | `"letsencrypt-cluster-issuer-key"` | no |
| cm\_namespace | Kubernetes namespace used by cert-manager. | `string` | `"cert-manager"` | no |
| cm\_repo | The cert-manager repository. | `string` | `"https://charts.jetstack.io"` | no |
| cm\_version | The cert-manager helm chart version | `string` | n/a | yes |
| diag\_logging\_eventhub\_authorization\_rule\_id | The rule ID allowing authorization to the eventhub. | `string` | `null` | no |
| diag\_logging\_eventhub\_name | The target eventhub name where audit logging will be sent. Use in conjuction with the eventhub\_authorization\_rule\_id | `string` | `null` | no |
| diag\_logging\_loganalytics\_id | The ID of the log analytics workspace to send diagnostic logging. | `string` | `null` | no |
| diag\_logging\_storage\_account\_id | The target storage account id where audit logging will be sent. | `string` | `null` | no |
| enable\_auditlogging\_to\_eventhub | Enable audit logging to a target eventhub. | `bool` | `false` | no |
| enable\_auditlogging\_to\_loganalytics | Enable audit logging to a target log analytics workspace. | `bool` | `false` | no |
| enable\_auditlogging\_to\_storage | Enable audit logging to a target storage account | `bool` | `false` | no |
| enable\_azure\_ddos\_protection | Enable DDOS protection for the vnet created by this terraform. Note: DDOS protection will significantly increase the cost of this subscription. | `bool` | `false` | no |
| enable\_kv\_metrics\_diag\_logging | When sending diagnostic logs for the eventhub resource, we can optionally enable metrics as well. | `bool` | `false` | no |
| humio\_operator\_chart\_version | This is the version of the helm chart that installs the humio operator version chosen in variable humio\_operator\_version. | `string` | n/a | yes |
| humio\_operator\_extra\_values | Resource Management for logscale pods | `map(string)` | <pre>{<br/>  "operator.resources.limits.cpu": "250m",<br/>  "operator.resources.limits.memory": "750Mi",<br/>  "operator.resources.requests.cpu": "250m",<br/>  "operator.resources.requests.memory": "750Mi"<br/>}</pre> | no |
| humio\_operator\_repo | The humio operator repository. | `string` | `"https://humio.github.io/humio-operator"` | no |
| humio\_operator\_version | The humio operator controls provisioning of logscale resources within kubernetes. | `string` | n/a | yes |
| ip\_ranges\_allowed\_https | List of IP Ranges that can access the ingress frontend for UI and logscale API operations, including ingestion. | `list` | `[]` | no |
| ip\_ranges\_allowed\_kv\_access | List of IP Ranges that can access the key vault. | `list` | `[]` | no |
| ip\_ranges\_allowed\_storage\_account\_access | IP ranges allowed to access created storage containers | `list` | `[]` | no |
| ip\_ranges\_allowed\_to\_bastion | (Optional) List of IP addresses or CIDR notated ranges that can access the bastion host. | `list(string)` | `[]` | no |
| ip\_ranges\_allowed\_to\_kubeapi | IP ranges allowed to access the public kubernetes api | `list` | `[]` | no |
| k8s\_automatic\_upgrade\_channel | Upgrade channel for the kubernetes cluster. | `string` | `"patch"` | no |
| k8s\_config\_path | The path that will contain the kubernetes configuration file, typically at ~/.kube/config | `string` | `"~/.kube/config"` | no |
| k8s\_general\_maintenance\_windows | This specifies when maintenance operations can be performed on the cluster and will take priority when more specific schedules are not set (i.e. maintenance\_window\_auto\_upgrade, maintenance\_window\_node\_os). | <pre>list(object({<br/>        day   = string<br/>        hours = list(number)<br/>    }))</pre> | <pre>[<br/>  {<br/>    "day": "Sunday",<br/>    "hours": [<br/>      2,<br/>      3,<br/>      4<br/>    ]<br/>  }<br/>]</pre> | no |
| k8s\_maintenance\_window\_auto\_upgrade | Allows for more granular control over AKS auto upgrades | <pre>object({<br/>    frequency    = string       # "Weekly", "RelativeMonthly"<br/>    interval     = number       # How often the schedule occurs (e.g., every 1 week/month)<br/>    duration     = number       # Length of maintenance window in hours<br/>    day_of_week  = string       # Required for Weekly frequency<br/>    utc_offset   = string       # e.g., "+00:00", "-07:00"<br/>    start_time   = string       # 24-hour format "HH:mm"<br/>    week_index   = optional(string) # Required when frequency is RelativeMonthly<br/>  })</pre> | `null` | no |
| k8s\_maintenance\_window\_node\_os | Sets a maintenance window for OS upgrades to AKS nodes. | <pre>object({<br/>    frequency    = string               # "Weekly", "RelativeMonthly"<br/>    interval     = number               # How often the schedule occurs (e.g., every 1 week/month)<br/>    duration     = number               # Length of maintenance window in hours<br/>    day_of_week  = string               # Required for Weekly / RelativeMonthly frequency<br/>    utc_offset   = string               # e.g., "+00:00", "-07:00"<br/>    start_time   = string               # 24-hour format "HH:mm"<br/>    week_index   = optional(string)     # Required when frequency is RelativeMonthly<br/>  })</pre> | `null` | no |
| k8s\_namespace\_prefix | Multiple namespaces will be created to contain resources using this prefix. | `string` | `"log"` | no |
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
| logscale\_custom\_tls\_certificate\_key\_keyvault\_name | Name of the TLS certificate key item (PEM format) stored in the Azure Keyvault created by this terraform | `string` | `null` | no |
| logscale\_custom\_tls\_certificate\_keyvault\_name | Name of the TLS certificate item (PEM format) stored in the Azure Keyvault created by this terraform | `string` | `null` | no |
| logscale\_image | This can be used to specify a full image ref spec. The expectation is that the imagePullSecrets kubernetes secret will exist. | `string` | `null` | no |
| logscale\_image\_version | The version of logscale to install. | `string` | `""` | no |
| logscale\_lb\_internal\_only | The nginx ingress controller to logscale will create a managed azure load balancer with public availability. Setting to true will remove the ability to generate Let's Encrypt certificates in addition to removing public access. | `bool` | `false` | no |
| logscale\_license | Your logscale license data. | `string` | n/a | yes |
| logscale\_namespace | The kubernetes namespace used by strimzi, logscale, and nginx-ingress. | `string` | `"logging"` | no |
| logscale\_update\_strategy | When describing a HumioCluster resource, you can provide a map value to describe how updates should be applied. Defaults to RollingUpdateBestEffort, 50% maximum unavailable, zone awareness enabled. Reference: https://github.com/humio/humio-operator/blob/master/docs/api.md#humioclusterspecupdatestrategy | `map` | <pre>{<br/>  "enableZoneAwareness": true,<br/>  "maxUnavailable": "50%",<br/>  "minReadySeconds": 120,<br/>  "type": "RollingUpdateBestEffort"<br/>}</pre> | no |
| network\_subnet\_aks\_ingest\_nodes | A list of networks to associate to the ingress node subnet. | `list` | <pre>[<br/>  "172.16.5.0/24"<br/>]</pre> | no |
| network\_subnet\_aks\_ingress\_nodes | A list of networks to associate to the ingress node subnet. | `list` | <pre>[<br/>  "172.16.4.0/24"<br/>]</pre> | no |
| network\_subnet\_aks\_logscale\_digest\_nodes | Subnet for the kubernetes node pool hosting logscale digest nodes. | `list` | <pre>[<br/>  "172.16.3.0/24"<br/>]</pre> | no |
| network\_subnet\_aks\_system\_nodes | Subnet for kubernetes system nodes. In the basic architecture, this will also be where nginx ingress nodes are placed. | `list` | <pre>[<br/>  "172.16.0.0/24"<br/>]</pre> | no |
| network\_subnet\_aks\_ui\_nodes | A list of networks to associate to the ingress node subnet. | `list` | <pre>[<br/>  "172.16.6.0/24"<br/>]</pre> | no |
| network\_subnet\_bastion\_nodes | Subnet for bastion nodes. | `list` | <pre>[<br/>  "172.16.1.0/26"<br/>]</pre> | no |
| network\_subnet\_kafka\_nodes | Subnet for kubernetes node pool hosting the strimzi kafka nodes | `list` | <pre>[<br/>  "172.16.2.0/24"<br/>]</pre> | no |
| nginx\_ingress\_helm\_chart\_version | The version of nginx-ingress to install in the environment. Reference: github.com/kubernetes/ingress-nginx for helm chart version to nginx version mapping. | `string` | n/a | yes |
| password\_rotation\_arbitrary\_value | This will not influence the password generated for logscale but, when modified, will cause the password to be regenerated. | `string` | `"defaultstring"` | no |
| provision\_kafka\_servers | Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation. | `bool` | `true` | no |
| resource\_name\_prefix | Identifier attached to named resources to help them stand out. Must be 8 or fewer characters which can include lower case, numbers, and hyphens. | `string` | `"log"` | no |
| set\_kv\_expiration\_dates | Setting expiration dates on vault secrets will help ensure that secrets are not retained forever but it's not always feasible to have static expiration dates. Set this to false to disable expirations. | `bool` | `true` | no |
| strimzi\_operator\_chart\_version | Helm chart version for installing strimzi. | `string` | n/a | yes |
| strimzi\_operator\_repo | Strimzi operator repo. | `string` | `"https://strimzi.io/charts/"` | no |
| strimzi\_operator\_version | Strimzi operator version for resource definition installation. | `string` | n/a | yes |
| tags | A map of tags to apply to all created resources. | `map` | `{}` | no |
| topo\_lvm\_chart\_version | Version of topo lvm to install. | `string` | n/a | yes |
| use\_own\_certificate\_for\_ingress | Set to true if you plan to bring your own certificate for logscale ingest/ui access. | `bool` | `false` | no |
| user\_logscale\_envvars | These are environment variables passed into the HumioCluster resource spec definition that will be used for all created logscale instances. Supports string values and kubernetes secret refs. Will override any values defined by default in the configuration. | <pre>list(object({<br/>    name=string,<br/>    value=optional(string)<br/>    valueFrom=optional(object({<br/>      secretKeyRef = object({<br/>        name = string<br/>        key = string<br/>      })<br/>    }))<br/>  }))</pre> | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| azure\_keyvault\_name | n/a |
| k8s\_cluster\_id | n/a |
| k8s\_cluster\_name | Kubernetes information |
| k8s\_configuration\_command | Run this command after building the kubernetes cluster to set your local kube config |
| logscale-ingress-fqdn | Public FQDN for access to logscale environment via Azure LB, when public access is enabled |
| logscale-ingress-ip | Public IP address for access to logscale environment via Azure LB, when public access is enabled |
| resource\_group\_name | n/a |
| resource\_name\_prefix | Prefix added to resources for unique identification |

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
| <a name="input_bastion_network_subnet"></a> [bastion\_network\_subnet](#input\_bastion\_network\_subnet) | A list of networks to associate to the bastion host subnet. | `list` | n/a | yes |
| <a name="input_enable_azure_ddos_protection"></a> [enable\_azure\_ddos\_protection](#input\_enable\_azure\_ddos\_protection) | Enable Azure DDOS Protection | `bool` | n/a | yes |
| <a name="input_enabled_logscale_digest_service_endpoints"></a> [enabled\_logscale\_digest\_service\_endpoints](#input\_enabled\_logscale\_digest\_service\_endpoints) | List of service endpoints required for the subnet. Storage is required for vnet-only access. | `list` | <pre>[<br/>  "Microsoft.Storage"<br/>]</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Azure cloud enviroment to use for your resources. Values include: public, usgovernment, german, and china. | `string` | n/a | yes |
| <a name="input_logscale_cluster_type"></a> [logscale\_cluster\_type](#input\_logscale\_cluster\_type) | Type of cluster being built. | `string` | n/a | yes |
| <a name="input_logscale_lb_internal_only"></a> [logscale\_lb\_internal\_only](#input\_logscale\_lb\_internal\_only) | The nginx ingress controller to logscale will create a managed azure load balancer with public availability. In this core module, this variable determines if the public IP address for this load balancer needs to be created. | `bool` | `false` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| <a name="input_network_subnet_aks_logscale_digest_nodes"></a> [network\_subnet\_aks\_logscale\_digest\_nodes](#input\_network\_subnet\_aks\_logscale\_digest\_nodes) | A list of networks to associate to the kubernetes subnet. | `list` | n/a | yes |
| <a name="input_network_subnet_aks_system_nodes"></a> [network\_subnet\_aks\_system\_nodes](#input\_network\_subnet\_aks\_system\_nodes) | A list of networks to associate to the kubernetes subnet. | `list` | n/a | yes |
| <a name="input_network_subnet_ingest_nodes"></a> [network\_subnet\_ingest\_nodes](#input\_network\_subnet\_ingest\_nodes) | A list of networks to associate to the ingest node subnet. | `list` | n/a | yes |
| <a name="input_network_subnet_ingress_nodes"></a> [network\_subnet\_ingress\_nodes](#input\_network\_subnet\_ingress\_nodes) | A list of networks to associate to the ingress node subnet. | `list` | n/a | yes |
| <a name="input_network_subnet_kafka_nodes"></a> [network\_subnet\_kafka\_nodes](#input\_network\_subnet\_kafka\_nodes) | A list of networks to associate to the kafka subnet. | `list` | n/a | yes |
| <a name="input_network_subnet_ui_nodes"></a> [network\_subnet\_ui\_nodes](#input\_network\_subnet\_ui\_nodes) | A list of networks to associate to the ui node subnet. | `list` | n/a | yes |
| <a name="input_provision_kafka_servers"></a> [provision\_kafka\_servers](#input\_provision\_kafka\_servers) | Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation. | `bool` | `true` | no |
| <a name="input_resource_group_region"></a> [resource\_group\_region](#input\_resource\_group\_region) | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Subscription ID for your Azure resources. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all created resources. | `map` | n/a | yes |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | Address space to assign to the virtual network that will resources associated to the kubernetes cluster. | `list` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_subnet_id"></a> [bastion\_subnet\_id](#output\_bastion\_subnet\_id) | n/a |
| <a name="output_ingress-pub-fqdn"></a> [ingress-pub-fqdn](#output\_ingress-pub-fqdn) | FQDN for logscale ingress when using a public endpoint. |
| <a name="output_ingress-pub-ip"></a> [ingress-pub-ip](#output\_ingress-pub-ip) | IP Address for logscale ingress when using a public endpoint. |
| <a name="output_ingress-pub-pip-name"></a> [ingress-pub-pip-name](#output\_ingress-pub-pip-name) | n/a |
| <a name="output_ingress-pup-pip-domain-name-label"></a> [ingress-pup-pip-domain-name-label](#output\_ingress-pup-pip-domain-name-label) | n/a |
| <a name="output_kafka_nodes_subnet_id"></a> [kafka\_nodes\_subnet\_id](#output\_kafka\_nodes\_subnet\_id) | n/a |
| <a name="output_logscale_digest_nodes_subnet_id"></a> [logscale\_digest\_nodes\_subnet\_id](#output\_logscale\_digest\_nodes\_subnet\_id) | n/a |
| <a name="output_logscale_ingest_nodes_subnet_id"></a> [logscale\_ingest\_nodes\_subnet\_id](#output\_logscale\_ingest\_nodes\_subnet\_id) | n/a |
| <a name="output_logscale_ingress_nodes_subnet_id"></a> [logscale\_ingress\_nodes\_subnet\_id](#output\_logscale\_ingress\_nodes\_subnet\_id) | n/a |
| <a name="output_logscale_ui_nodes_subnet_id"></a> [logscale\_ui\_nodes\_subnet\_id](#output\_logscale\_ui\_nodes\_subnet\_id) | n/a |
| <a name="output_nat_gw_public_ip"></a> [nat\_gw\_public\_ip](#output\_nat\_gw\_public\_ip) | NAT GW IP address for your subnets which can be used to allow access as necessary to other environments. |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Azure Resource Group |
| <a name="output_resource_group_region"></a> [resource\_group\_region](#output\_resource\_group\_region) | n/a |
| <a name="output_system_nodes_subnet_id"></a> [system\_nodes\_subnet\_id](#output\_system\_nodes\_subnet\_id) | n/a |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | n/a |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | n/a |

<!-- END_AZCORE_MAIN_DOCS -->

<!-- BEGIN_AZAKS_MAIN_DOCS -->
## Module: azure/aks
This module provisions managed Azure Kubernetes within the environment.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_ssh_pubkey"></a> [admin\_ssh\_pubkey](#input\_admin\_ssh\_pubkey) | Public key for SSH access to the bastion host. | `string` | n/a | yes |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Admin username for ssh access to k8s nodes. | `string` | n/a | yes |
| <a name="input_aks_system_nodes_subnet_id"></a> [aks\_system\_nodes\_subnet\_id](#input\_aks\_system\_nodes\_subnet\_id) | Subnet ID for AKS system nodes to live in. | `any` | n/a | yes |
| <a name="input_authorized_ip_ranges"></a> [authorized\_ip\_ranges](#input\_authorized\_ip\_ranges) | IP Ranges allowed to access the public kubernetes API | `list` | `[]` | no |
| <a name="input_azure_availability_zones"></a> [azure\_availability\_zones](#input\_azure\_availability\_zones) | The availability zones to use with your kubernetes cluster. Defaults to null making the cluster regional with no guarantee of HA in the event of zone outage. | `list` | `null` | no |
| <a name="input_azure_keyvault_id"></a> [azure\_keyvault\_id](#input\_azure\_keyvault\_id) | Azure KeyVault id used for storing secrets related to this infrastructure | `string` | n/a | yes |
| <a name="input_azure_keyvault_secret_expiration_date"></a> [azure\_keyvault\_secret\_expiration\_date](#input\_azure\_keyvault\_secret\_expiration\_date) | When secrets should expire. | `string` | n/a | yes |
| <a name="input_azure_policy_enabled"></a> [azure\_policy\_enabled](#input\_azure\_policy\_enabled) | Enable the Azure Policy for AKS add-on? | `bool` | n/a | yes |
| <a name="input_cost_analysis_enabled"></a> [cost\_analysis\_enabled](#input\_cost\_analysis\_enabled) | Enable cost analysis for this AKS cluster? | `bool` | n/a | yes |
| <a name="input_diag_logging_eventhub_authorization_rule_id"></a> [diag\_logging\_eventhub\_authorization\_rule\_id](#input\_diag\_logging\_eventhub\_authorization\_rule\_id) | The rule ID allowing authorization to the eventhub. | `string` | `null` | no |
| <a name="input_diag_logging_eventhub_name"></a> [diag\_logging\_eventhub\_name](#input\_diag\_logging\_eventhub\_name) | The target eventhub name where audit logging will be sent. Use in conjuction with the eventhub\_authorization\_rule\_id | `string` | `null` | no |
| <a name="input_diag_logging_loganalytics_id"></a> [diag\_logging\_loganalytics\_id](#input\_diag\_logging\_loganalytics\_id) | The ID of the log analytics workspace to send diagnostic logging. | `string` | `null` | no |
| <a name="input_diag_logging_storage_account_id"></a> [diag\_logging\_storage\_account\_id](#input\_diag\_logging\_storage\_account\_id) | The target storage account id where audit logging will be sent. | `string` | `null` | no |
| <a name="input_disk_encryption_key_expiration_date"></a> [disk\_encryption\_key\_expiration\_date](#input\_disk\_encryption\_key\_expiration\_date) | Optionally set when the disk encryption key used for AKS nodes should expire. Defaults to null on the assumption that this AKS cluster might be long-lived. | `string` | `null` | no |
| <a name="input_enable_auditlogging_to_eventhub"></a> [enable\_auditlogging\_to\_eventhub](#input\_enable\_auditlogging\_to\_eventhub) | Enable audit logging to a target eventhub. | `bool` | `false` | no |
| <a name="input_enable_auditlogging_to_loganalytics"></a> [enable\_auditlogging\_to\_loganalytics](#input\_enable\_auditlogging\_to\_loganalytics) | Enable audit logging to a target log analytics workspace. | `bool` | `false` | no |
| <a name="input_enable_auditlogging_to_storage"></a> [enable\_auditlogging\_to\_storage](#input\_enable\_auditlogging\_to\_storage) | Enable audit logging to a target storage account | `bool` | `false` | no |
| <a name="input_enable_kv_metrics_diag_logging"></a> [enable\_kv\_metrics\_diag\_logging](#input\_enable\_kv\_metrics\_diag\_logging) | When sending diagnostic logs for the eventhub resource, we can optionally enable metrics as well. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Azure cloud enviroment to use for your resources. | `string` | n/a | yes |
| <a name="input_ip_ranges_allowed_https"></a> [ip\_ranges\_allowed\_https](#input\_ip\_ranges\_allowed\_https) | IP Ranges allowed to access the nginx-ingress loadbalancer pods | `list` | `[]` | no |
| <a name="input_k8s_automatic_upgrade_channel"></a> [k8s\_automatic\_upgrade\_channel](#input\_k8s\_automatic\_upgrade\_channel) | Upgrade channel for the kubernetes cluster. | `string` | `"patch"` | no |
| <a name="input_k8s_general_maintenance_windows"></a> [k8s\_general\_maintenance\_windows](#input\_k8s\_general\_maintenance\_windows) | This specifies when maintenance operations can be performed on the cluster and will take priority when more specific schedules are not set (i.e. maintenance\_window\_auto\_upgrade, maintenance\_window\_node\_os). | <pre>list(object({<br/>        day   = string<br/>        hours = list(number)<br/>    }))</pre> | <pre>[<br/>  {<br/>    "day": "Sunday",<br/>    "hours": [<br/>      2,<br/>      3,<br/>      4<br/>    ]<br/>  }<br/>]</pre> | no |
| <a name="input_k8s_maintenance_window_auto_upgrade"></a> [k8s\_maintenance\_window\_auto\_upgrade](#input\_k8s\_maintenance\_window\_auto\_upgrade) | Allows for more granular control over AKS auto upgrades | <pre>object({<br/>    frequency    = string       # "Weekly", "RelativeMonthly"<br/>    interval     = number       # How often the schedule occurs (e.g., every 1 week/month)<br/>    duration     = number       # Length of maintenance window in hours<br/>    day_of_week  = string       # Required for Weekly frequency<br/>    utc_offset   = string       # e.g., "+00:00", "-07:00"<br/>    start_time   = string       # 24-hour format "HH:mm"<br/>    week_index   = optional(string) # Required when frequency is RelativeMonthly<br/>  })</pre> | `null` | no |
| <a name="input_k8s_maintenance_window_node_os"></a> [k8s\_maintenance\_window\_node\_os](#input\_k8s\_maintenance\_window\_node\_os) | Sets a maintenance window for OS upgrades to AKS nodes. | <pre>object({<br/>    frequency    = string               # "Weekly", "RelativeMonthly"<br/>    interval     = number               # How often the schedule occurs (e.g., every 1 week/month)<br/>    duration     = number               # Length of maintenance window in hours<br/>    day_of_week  = string               # Required for Weekly / RelativeMonthly frequency<br/>    utc_offset   = string               # e.g., "+00:00", "-07:00"<br/>    start_time   = string               # 24-hour format "HH:mm"<br/>    week_index   = optional(string)     # Required when frequency is RelativeMonthly<br/>  })</pre> | `null` | no |
| <a name="input_k8s_node_os_upgrade_channel"></a> [k8s\_node\_os\_upgrade\_channel](#input\_k8s\_node\_os\_upgrade\_channel) | Upgrade channel for the kubernetes nodes. | `string` | `"SecurityPatch"` | no |
| <a name="input_kafka_nodes_subnet_id"></a> [kafka\_nodes\_subnet\_id](#input\_kafka\_nodes\_subnet\_id) | Subnet ID where kafka nodes will live. | `string` | n/a | yes |
| <a name="input_kubernetes_diagnostic_log_categories"></a> [kubernetes\_diagnostic\_log\_categories](#input\_kubernetes\_diagnostic\_log\_categories) | List of enabled diagnostic log categories for the kubernetes cluster. | `list` | <pre>[<br/>  "kube-apiserver",<br/>  "kube-controller-manager",<br/>  "kube-scheduler",<br/>  "kube-audit",<br/>  "kube-audit-admin"<br/>]</pre> | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Allows specification of the kubernetes version for AKS. Default of 'null' forces use of the latest recommended version at time of provisioning. | `string` | `null` | no |
| <a name="input_logscale_cluster_type"></a> [logscale\_cluster\_type](#input\_logscale\_cluster\_type) | Logscale cluster type | `string` | n/a | yes |
| <a name="input_logscale_digest_nodes_subnet_id"></a> [logscale\_digest\_nodes\_subnet\_id](#input\_logscale\_digest\_nodes\_subnet\_id) | Subnet ID for logscale digest nodes. | `any` | n/a | yes |
| <a name="input_logscale_ingest_node_desired_count"></a> [logscale\_ingest\_node\_desired\_count](#input\_logscale\_ingest\_node\_desired\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ingest_node_max_count"></a> [logscale\_ingest\_node\_max\_count](#input\_logscale\_ingest\_node\_max\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ingest_node_min_count"></a> [logscale\_ingest\_node\_min\_count](#input\_logscale\_ingest\_node\_min\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ingest_nodes_subnet_id"></a> [logscale\_ingest\_nodes\_subnet\_id](#input\_logscale\_ingest\_nodes\_subnet\_id) | Subnet ID for ingest nodes. | `any` | n/a | yes |
| <a name="input_logscale_ingest_os_disk_size"></a> [logscale\_ingest\_os\_disk\_size](#input\_logscale\_ingest\_os\_disk\_size) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ingest_vmsize"></a> [logscale\_ingest\_vmsize](#input\_logscale\_ingest\_vmsize) | n/a | `string` | n/a | yes |
| <a name="input_logscale_ingress_node_desired_count"></a> [logscale\_ingress\_node\_desired\_count](#input\_logscale\_ingress\_node\_desired\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ingress_node_max_count"></a> [logscale\_ingress\_node\_max\_count](#input\_logscale\_ingress\_node\_max\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ingress_node_min_count"></a> [logscale\_ingress\_node\_min\_count](#input\_logscale\_ingress\_node\_min\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ingress_nodes_subnet_id"></a> [logscale\_ingress\_nodes\_subnet\_id](#input\_logscale\_ingress\_nodes\_subnet\_id) | Subnet ID for ingest nodes. | `any` | n/a | yes |
| <a name="input_logscale_ingress_os_disk_size"></a> [logscale\_ingress\_os\_disk\_size](#input\_logscale\_ingress\_os\_disk\_size) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ingress_vmsize"></a> [logscale\_ingress\_vmsize](#input\_logscale\_ingress\_vmsize) | n/a | `string` | n/a | yes |
| <a name="input_logscale_node_desired_count"></a> [logscale\_node\_desired\_count](#input\_logscale\_node\_desired\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_node_max_count"></a> [logscale\_node\_max\_count](#input\_logscale\_node\_max\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_node_min_count"></a> [logscale\_node\_min\_count](#input\_logscale\_node\_min\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_node_os_disk_size_gb"></a> [logscale\_node\_os\_disk\_size\_gb](#input\_logscale\_node\_os\_disk\_size\_gb) | n/a | `number` | n/a | yes |
| <a name="input_logscale_node_vmsize"></a> [logscale\_node\_vmsize](#input\_logscale\_node\_vmsize) | n/a | `string` | n/a | yes |
| <a name="input_logscale_ui_node_desired_count"></a> [logscale\_ui\_node\_desired\_count](#input\_logscale\_ui\_node\_desired\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ui_node_max_count"></a> [logscale\_ui\_node\_max\_count](#input\_logscale\_ui\_node\_max\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ui_node_min_count"></a> [logscale\_ui\_node\_min\_count](#input\_logscale\_ui\_node\_min\_count) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ui_nodes_subnet_id"></a> [logscale\_ui\_nodes\_subnet\_id](#input\_logscale\_ui\_nodes\_subnet\_id) | Subnet ID for ingest nodes. | `any` | n/a | yes |
| <a name="input_logscale_ui_os_disk_size"></a> [logscale\_ui\_os\_disk\_size](#input\_logscale\_ui\_os\_disk\_size) | n/a | `number` | n/a | yes |
| <a name="input_logscale_ui_vmsize"></a> [logscale\_ui\_vmsize](#input\_logscale\_ui\_vmsize) | n/a | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| <a name="input_private_cluster_enabled"></a> [private\_cluster\_enabled](#input\_private\_cluster\_enabled) | Should the kubernetes API be private only? Setting to private has implications to how to run this IaaC. Refer to documentation for more detail. | `bool` | n/a | yes |
| <a name="input_provision_kafka_servers"></a> [provision\_kafka\_servers](#input\_provision\_kafka\_servers) | Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation. | `bool` | `true` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The ID of the resource group where the kubernetes managed identity will be granted network contributor access. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| <a name="input_resource_group_region"></a> [resource\_group\_region](#input\_resource\_group\_region) | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | Tier for the AKS cluster, Standard or Premium | `string` | `"Standard"` | no |
| <a name="input_strimzi_node_desired_count"></a> [strimzi\_node\_desired\_count](#input\_strimzi\_node\_desired\_count) | n/a | `number` | n/a | yes |
| <a name="input_strimzi_node_instance_type"></a> [strimzi\_node\_instance\_type](#input\_strimzi\_node\_instance\_type) | n/a | `string` | n/a | yes |
| <a name="input_strimzi_node_max_count"></a> [strimzi\_node\_max\_count](#input\_strimzi\_node\_max\_count) | n/a | `number` | n/a | yes |
| <a name="input_strimzi_node_min_count"></a> [strimzi\_node\_min\_count](#input\_strimzi\_node\_min\_count) | n/a | `number` | n/a | yes |
| <a name="input_strimzi_node_os_disk_size_gb"></a> [strimzi\_node\_os\_disk\_size\_gb](#input\_strimzi\_node\_os\_disk\_size\_gb) | n/a | `number` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Subscription ID for your Azure resources. | `string` | n/a | yes |
| <a name="input_system_node_desired_count"></a> [system\_node\_desired\_count](#input\_system\_node\_desired\_count) | n/a | `number` | n/a | yes |
| <a name="input_system_node_max_count"></a> [system\_node\_max\_count](#input\_system\_node\_max\_count) | n/a | `number` | n/a | yes |
| <a name="input_system_node_min_count"></a> [system\_node\_min\_count](#input\_system\_node\_min\_count) | n/a | `number` | n/a | yes |
| <a name="input_system_node_os_disk_size_gb"></a> [system\_node\_os\_disk\_size\_gb](#input\_system\_node\_os\_disk\_size\_gb) | n/a | `number` | n/a | yes |
| <a name="input_system_node_vmsize"></a> [system\_node\_vmsize](#input\_system\_node\_vmsize) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all created resources. | `map` | n/a | yes |
| <a name="input_use_custom_certificate"></a> [use\_custom\_certificate](#input\_use\_custom\_certificate) | Use a custom provided certificate for ingress. In this module, this setting controls creation of a NSG rule that allows for Let's Encrypt ACME challenges. | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_k8s_client_certificate_kv_name"></a> [k8s\_client\_certificate\_kv\_name](#output\_k8s\_client\_certificate\_kv\_name) | n/a |
| <a name="output_k8s_client_key_kv_name"></a> [k8s\_client\_key\_kv\_name](#output\_k8s\_client\_key\_kv\_name) | n/a |
| <a name="output_k8s_cluster_ca_certificate_kv_name"></a> [k8s\_cluster\_ca\_certificate\_kv\_name](#output\_k8s\_cluster\_ca\_certificate\_kv\_name) | n/a |
| <a name="output_k8s_cluster_endpoint"></a> [k8s\_cluster\_endpoint](#output\_k8s\_cluster\_endpoint) | n/a |
| <a name="output_k8s_cluster_id"></a> [k8s\_cluster\_id](#output\_k8s\_cluster\_id) | n/a |
| <a name="output_k8s_cluster_name"></a> [k8s\_cluster\_name](#output\_k8s\_cluster\_name) | n/a |
| <a name="output_k8s_cluster_principal_id"></a> [k8s\_cluster\_principal\_id](#output\_k8s\_cluster\_principal\_id) | Kubernetes information |
| <a name="output_k8s_kube_config_kv_name"></a> [k8s\_kube\_config\_kv\_name](#output\_k8s\_kube\_config\_kv\_name) | n/a |

<!-- END_AZAKS_MAIN_DOCS -->

<!-- BEGIN_AZBAS_MAIN_DOCS -->
## Module: azure/bastion
An optional module that can be used to provision a bastion host. This is particularly useful when provisioning a brand new
environment and setting the kubernetes API to private access only.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_ssh_pubkey"></a> [admin\_ssh\_pubkey](#input\_admin\_ssh\_pubkey) | Public key for SSH access to the bastion host. | `string` | n/a | yes |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Admin username for ssh access to k8s nodes. | `string` | n/a | yes |
| <a name="input_bastion_host_size"></a> [bastion\_host\_size](#input\_bastion\_host\_size) | Sizing for the bastion host. | `string` | n/a | yes |
| <a name="input_bastion_subnet_id"></a> [bastion\_subnet\_id](#input\_bastion\_subnet\_id) | Subnet ID to attach the bastion host NIC. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Azure cloud enviroment to use for your resources. | `string` | n/a | yes |
| <a name="input_ip_ranges_allowed"></a> [ip\_ranges\_allowed](#input\_ip\_ranges\_allowed) | List of IP addresses or CIDR notated ranges that can access the bastion host. | `list` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| <a name="input_resource_group_region"></a> [resource\_group\_region](#input\_resource\_group\_region) | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Subscription ID for your Azure resources. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all created resources. | `map` | n/a | yes |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Name of the virtual network where this resource will live | `string` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_host_private_ip"></a> [bastion\_host\_private\_ip](#output\_bastion\_host\_private\_ip) | n/a |
| <a name="output_bastion_nsg_name"></a> [bastion\_nsg\_name](#output\_bastion\_nsg\_name) | n/a |
| <a name="output_bastion_public_dns_name"></a> [bastion\_public\_dns\_name](#output\_bastion\_public\_dns\_name) | n/a |
| <a name="output_bastion_public_ip_address"></a> [bastion\_public\_ip\_address](#output\_bastion\_public\_ip\_address) | Bastion Host Connection Information |

<!-- END_AZBAS_MAIN_DOCS -->

<!-- BEGIN_AZCERT_MAIN_DOCS -->
## Module: azure/certificate
An optional module that can be used to provision a certificate within Azure KeyVault. This is expected to be used for self-signed
test certificates but depending on the configuration of your KeyVault, it can be leveraged to provsion valid certs.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_keyvault_id"></a> [azure\_keyvault\_id](#input\_azure\_keyvault\_id) | The Azure Keyvault ID storing all the secrets above. | `string` | n/a | yes |
| <a name="input_cert_issuer"></a> [cert\_issuer](#input\_cert\_issuer) | The issuer to use for certificate generation. Defaults to Self but can match any issuer registered in your environment. | `string` | `"Self"` | no |
| <a name="input_logscale_public_fqdn"></a> [logscale\_public\_fqdn](#input\_logscale\_public\_fqdn) | The FQDN tied to the public IP address for logscale ingress. This is the resource that will have a certificate provisioned from let's encrypt. | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| <a name="input_subject_alternative_names"></a> [subject\_alternative\_names](#input\_subject\_alternative\_names) | List of alternative names for the certificate. | `list` | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_certificate_keyvault_name"></a> [certificate\_keyvault\_name](#output\_certificate\_keyvault\_name) | n/a |

<!-- END_AZCERT_MAIN_DOCS -->

<!-- BEGIN_AZIDENT_MAIN_DOCS -->
## Module: azure/identity
This optional module can be used to provision a managed identity in Azure and assign a role to the identity.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| <a name="input_resource_group_region"></a> [resource\_group\_region](#input\_resource\_group\_region) | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| <a name="input_role_definition_name"></a> [role\_definition\_name](#input\_role\_definition\_name) | Built-in role definition to assign to the created identity | `string` | `"Storage Blob Data Owner"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all created resources. | `map` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_managed_identity_resource_id"></a> [managed\_identity\_resource\_id](#output\_managed\_identity\_resource\_id) | n/a |
| <a name="output_managed_identity_resource_principal_id"></a> [managed\_identity\_resource\_principal\_id](#output\_managed\_identity\_resource\_principal\_id) | n/a |

<!-- END_AZIDENT_MAIN_DOCS -->

<!-- BEGIN_AZKV_MAIN_DOCS -->
## Module: azure/keyvault
This module provisions an Azure Keyvault for storing sensititve environment secrets for use across terraform modules.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificate_permissions"></a> [certificate\_permissions](#input\_certificate\_permissions) | The keyvault will be created with an access policy that grants permission to the calling user to do most things for the purposes of this terraform run. These permissions can be adjusted as required. | `list` | <pre>[<br/>  "Create",<br/>  "Delete",<br/>  "Get",<br/>  "GetIssuers",<br/>  "Import",<br/>  "List",<br/>  "ListIssuers",<br/>  "Update"<br/>]</pre> | no |
| <a name="input_diag_logging_eventhub_authorization_rule_id"></a> [diag\_logging\_eventhub\_authorization\_rule\_id](#input\_diag\_logging\_eventhub\_authorization\_rule\_id) | The rule ID allowing authorization to the eventhub. | `string` | `null` | no |
| <a name="input_diag_logging_eventhub_name"></a> [diag\_logging\_eventhub\_name](#input\_diag\_logging\_eventhub\_name) | The target eventhub name where audit logging for the keyvault will be sent. Use in conjuction with the eventhub\_authorization\_rule\_id | `string` | `null` | no |
| <a name="input_diag_logging_loganalytics_id"></a> [diag\_logging\_loganalytics\_id](#input\_diag\_logging\_loganalytics\_id) | The ID of the log analytics workspace to send diagnostic logging. | `string` | `null` | no |
| <a name="input_diag_logging_storage_account_id"></a> [diag\_logging\_storage\_account\_id](#input\_diag\_logging\_storage\_account\_id) | The target storage account id where audit logging for the keyvault will be sent. | `string` | `null` | no |
| <a name="input_enable_auditlogging_to_eventhub"></a> [enable\_auditlogging\_to\_eventhub](#input\_enable\_auditlogging\_to\_eventhub) | Enable audit logging to a target eventhub. | `bool` | `false` | no |
| <a name="input_enable_auditlogging_to_loganalytics"></a> [enable\_auditlogging\_to\_loganalytics](#input\_enable\_auditlogging\_to\_loganalytics) | Enable audit logging to a target log analytics workspace. | `bool` | `false` | no |
| <a name="input_enable_auditlogging_to_storage"></a> [enable\_auditlogging\_to\_storage](#input\_enable\_auditlogging\_to\_storage) | Enable audit logging to a target storage account | `bool` | `false` | no |
| <a name="input_enable_kv_metrics_diag_logging"></a> [enable\_kv\_metrics\_diag\_logging](#input\_enable\_kv\_metrics\_diag\_logging) | When sending diagnostic logs for the eventhub resource, we can optionally enable metrics as well. | `bool` | `false` | no |
| <a name="input_enabled_for_deployment"></a> [enabled\_for\_deployment](#input\_enabled\_for\_deployment) | Allow virtual machines to retrieve certificates stored as secrets in the vault | `bool` | `true` | no |
| <a name="input_enabled_for_disk_encryption"></a> [enabled\_for\_disk\_encryption](#input\_enabled\_for\_disk\_encryption) | Allow azure disk encryption to retrieve and unwrap keys in the vault | `bool` | `true` | no |
| <a name="input_ip_ranges_allowed_kv_access"></a> [ip\_ranges\_allowed\_kv\_access](#input\_ip\_ranges\_allowed\_kv\_access) | IP Ranges allowed access to keyvault outside of trusted AzureServices. | `list` | `[]` | no |
| <a name="input_key_permissions"></a> [key\_permissions](#input\_key\_permissions) | The keyvault will be created with an access policy that grants permission to the calling user to do most things for the purposes of this terraform run. These permissions can be adjusted as required. | `list` | <pre>[<br/>  "Get",<br/>  "List",<br/>  "Update",<br/>  "Delete",<br/>  "Encrypt",<br/>  "Decrypt",<br/>  "WrapKey",<br/>  "UnwrapKey",<br/>  "Create",<br/>  "GetRotationPolicy",<br/>  "SetRotationPolicy",<br/>  "Recover",<br/>  "Purge",<br/>  "Backup"<br/>]</pre> | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled) | Enable purge protection for KV resources | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| <a name="input_resource_group_region"></a> [resource\_group\_region](#input\_resource\_group\_region) | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| <a name="input_secret_permissions"></a> [secret\_permissions](#input\_secret\_permissions) | The keyvault will be created with an access policy that grants permission to the calling user to do most things for the purposes of this terraform run. These permissions can be adjusted as required. | `list` | <pre>[<br/>  "Get",<br/>  "List",<br/>  "Set",<br/>  "Delete",<br/>  "Recover"<br/>]</pre> | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | Standard or Premium SKU for the key vault. | `string` | `"standard"` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | The number of days to retain items once soft-deleted. Values can be 7-90 | `number` | `7` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all created resources. | `map` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_keyvault_id"></a> [keyvault\_id](#output\_keyvault\_id) | n/a |
| <a name="output_keyvault_name"></a> [keyvault\_name](#output\_keyvault\_name) | n/a |

<!-- END_AZKV_MAIN_DOCS -->

<!-- BEGIN_AZSTOR_MAIN_DOCS -->
## Module: azure/storage
This module provisions a storage account and optional container designed for provisioning storage for Logscale Object storage.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_keyvault_id"></a> [azure\_keyvault\_id](#input\_azure\_keyvault\_id) | Azure KeyVault id used for storing secrets related to this infrastructure | `string` | n/a | yes |
| <a name="input_azure_keyvault_secret_expiration_date"></a> [azure\_keyvault\_secret\_expiration\_date](#input\_azure\_keyvault\_secret\_expiration\_date) | When secrets should expire. | `string` | n/a | yes |
| <a name="input_create_container"></a> [create\_container](#input\_create\_container) | n/a | `bool` | `false` | no |
| <a name="input_diag_logging_eventhub_authorization_rule_id"></a> [diag\_logging\_eventhub\_authorization\_rule\_id](#input\_diag\_logging\_eventhub\_authorization\_rule\_id) | The rule ID allowing authorization to the eventhub. | `string` | `null` | no |
| <a name="input_diag_logging_eventhub_name"></a> [diag\_logging\_eventhub\_name](#input\_diag\_logging\_eventhub\_name) | The target eventhub name where audit logging will be sent. Use in conjuction with the eventhub\_authorization\_rule\_id | `string` | `null` | no |
| <a name="input_diag_logging_loganalytics_id"></a> [diag\_logging\_loganalytics\_id](#input\_diag\_logging\_loganalytics\_id) | The ID of the log analytics workspace to send diagnostic logging. | `string` | `null` | no |
| <a name="input_diag_logging_storage_account_id"></a> [diag\_logging\_storage\_account\_id](#input\_diag\_logging\_storage\_account\_id) | The target storage account id where audit logging will be sent. | `string` | `null` | no |
| <a name="input_enable_auditlogging_to_eventhub"></a> [enable\_auditlogging\_to\_eventhub](#input\_enable\_auditlogging\_to\_eventhub) | Enable audit logging to a target eventhub. | `bool` | `false` | no |
| <a name="input_enable_auditlogging_to_loganalytics"></a> [enable\_auditlogging\_to\_loganalytics](#input\_enable\_auditlogging\_to\_loganalytics) | Enable audit logging to a target log analytics workspace. | `bool` | `false` | no |
| <a name="input_enable_auditlogging_to_storage"></a> [enable\_auditlogging\_to\_storage](#input\_enable\_auditlogging\_to\_storage) | Enable audit logging to a target storage account | `bool` | `false` | no |
| <a name="input_enable_hns"></a> [enable\_hns](#input\_enable\_hns) | n/a | `bool` | `true` | no |
| <a name="input_ip_ranges_allowed_storage_account_access"></a> [ip\_ranges\_allowed\_storage\_account\_access](#input\_ip\_ranges\_allowed\_storage\_account\_access) | IP Ranges allowed access to the storage account | `list` | `[]` | no |
| <a name="input_min_tls_version"></a> [min\_tls\_version](#input\_min\_tls\_version) | Minimum TLS version accepted by the storage container. | `string` | `"TLS1_2"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| <a name="input_resource_group_region"></a> [resource\_group\_region](#input\_resource\_group\_region) | The Azure cloud region for the resource group and associated resources. | `string` | n/a | yes |
| <a name="input_shared_access_key_enabled"></a> [shared\_access\_key\_enabled](#input\_shared\_access\_key\_enabled) | Allow shared access keys to the storage containers. Defaults to true, as of Logscale 1.174, this method of access is required. | `bool` | `true` | no |
| <a name="input_storage_access_default_action"></a> [storage\_access\_default\_action](#input\_storage\_access\_default\_action) | By default, allow or deny access to the storage account | `string` | `"Deny"` | no |
| <a name="input_storage_account_blob_log_categories"></a> [storage\_account\_blob\_log\_categories](#input\_storage\_account\_blob\_log\_categories) | List of enabled diagnostic log categories for the storage account. | `list` | <pre>[<br/>  "StorageRead",<br/>  "StorageWrite",<br/>  "StorageDelete"<br/>]</pre> | no |
| <a name="input_storage_account_file_log_categories"></a> [storage\_account\_file\_log\_categories](#input\_storage\_account\_file\_log\_categories) | List of enabled diagnostic log categories for the storage account. | `list` | <pre>[<br/>  "StorageRead",<br/>  "StorageWrite",<br/>  "StorageDelete"<br/>]</pre> | no |
| <a name="input_storage_account_kind"></a> [storage\_account\_kind](#input\_storage\_account\_kind) | n/a | `string` | `"StorageV2"` | no |
| <a name="input_storage_account_queue_log_categories"></a> [storage\_account\_queue\_log\_categories](#input\_storage\_account\_queue\_log\_categories) | List of enabled diagnostic log categories for the storage account. | `list` | <pre>[<br/>  "StorageRead",<br/>  "StorageWrite",<br/>  "StorageDelete"<br/>]</pre> | no |
| <a name="input_storage_account_replication"></a> [storage\_account\_replication](#input\_storage\_account\_replication) | n/a | `string` | `"LRS"` | no |
| <a name="input_storage_account_table_log_categories"></a> [storage\_account\_table\_log\_categories](#input\_storage\_account\_table\_log\_categories) | List of enabled diagnostic log categories for the storage account. | `list` | <pre>[<br/>  "StorageRead",<br/>  "StorageWrite",<br/>  "StorageDelete"<br/>]</pre> | no |
| <a name="input_storage_account_tier"></a> [storage\_account\_tier](#input\_storage\_account\_tier) | Storage account tier. | `string` | `"Standard"` | no |
| <a name="input_storage_network_rules_bypass"></a> [storage\_network\_rules\_bypass](#input\_storage\_network\_rules\_bypass) | Defines traffic that can bypass the network-based restrictions applied. Can be a list containing: Metrics, Logging, and/or AzureServices. Can also be set to: None | `list` | <pre>[<br/>  "AzureServices",<br/>  "Metrics",<br/>  "Logging"<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all created resources. | `map` | n/a | yes |
| <a name="input_vnet_subnets_allowed_storage_account_access"></a> [vnet\_subnets\_allowed\_storage\_account\_access](#input\_vnet\_subnets\_allowed\_storage\_account\_access) | List of subnet ids in the vnet allowed access to the storage account | `list` | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_storage_acct_access_key_kv"></a> [storage\_acct\_access\_key\_kv](#output\_storage\_acct\_access\_key\_kv) | n/a |
| <a name="output_storage_acct_blob_endpoint"></a> [storage\_acct\_blob\_endpoint](#output\_storage\_acct\_blob\_endpoint) | n/a |
| <a name="output_storage_acct_container_id"></a> [storage\_acct\_container\_id](#output\_storage\_acct\_container\_id) | n/a |
| <a name="output_storage_acct_container_name"></a> [storage\_acct\_container\_name](#output\_storage\_acct\_container\_name) | n/a |
| <a name="output_storage_acct_id"></a> [storage\_acct\_id](#output\_storage\_acct\_id) | n/a |
| <a name="output_storage_acct_name"></a> [storage\_acct\_name](#output\_storage\_acct\_name) | n/a |

<!-- END_AZSTOR_MAIN_DOCS -->

<!-- BEGIN_K8CRD_MAIN_DOCS -->
## Module: kubernetes/crds
This module installs custom resource definitions (crds) into the Kubernetes environment and is run in advance of any other
kubernetes module to ensure successful terraform planning.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cm_crds_url"></a> [cm\_crds\_url](#input\_cm\_crds\_url) | Cert Manager CRDs URL | `string` | `"https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml"` | no |
| <a name="input_humio_operator_version"></a> [humio\_operator\_version](#input\_humio\_operator\_version) | Humio Operator version | `string` | n/a | yes |
| <a name="input_k8s_config_context"></a> [k8s\_config\_context](#input\_k8s\_config\_context) | Configuration context name, typically the kubernetes server name. | `any` | n/a | yes |
| <a name="input_k8s_config_path"></a> [k8s\_config\_path](#input\_k8s\_config\_path) | The path to k8s configuration. | `any` | n/a | yes |
| <a name="input_strimzi_operator_version"></a> [strimzi\_operator\_version](#input\_strimzi\_operator\_version) | Used to get CRDs for strimzi and install them. | `string` | n/a | yes |

### Outputs

No outputs.

<!-- END_K8CRD_MAIN_DOCS -->

<!-- BEGIN_K8STRIMZ_MAIN_DOCS -->
## Module: kubernetes/strimzi
This module installs Strimzi Kafka in kraft mode for use with the logscale ingestion pipeline.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_k8s_config_context"></a> [k8s\_config\_context](#input\_k8s\_config\_context) | Configuration context name, typically the kubernetes server name. | `any` | n/a | yes |
| <a name="input_k8s_config_path"></a> [k8s\_config\_path](#input\_k8s\_config\_path) | The path to k8s configuration. | `any` | n/a | yes |
| <a name="input_k8s_namespace_prefix"></a> [k8s\_namespace\_prefix](#input\_k8s\_namespace\_prefix) | Multiple namespaces will be created to contain resources using this prefix. | `string` | n/a | yes |
| <a name="input_kafka_broker_data_disk_size"></a> [kafka\_broker\_data\_disk\_size](#input\_kafka\_broker\_data\_disk\_size) | The size of the data disk to provision for each kafka broker. (i.e. 2048Gi) | `string` | n/a | yes |
| <a name="input_kafka_broker_pod_replica_count"></a> [kafka\_broker\_pod\_replica\_count](#input\_kafka\_broker\_pod\_replica\_count) | The number of pods to run in this kafka cluster. | `number` | n/a | yes |
| <a name="input_kafka_broker_resources"></a> [kafka\_broker\_resources](#input\_kafka\_broker\_resources) | The resource requests and limits for cpu and memory to apply to the pods formatted in a json map. Example: {"limits": {"cpu": 6, "memory": "48Gi"}, "requests": {"cpu": 6, "memory": "48Gi"}} | `map` | n/a | yes |
| <a name="input_kube_storage_class_for_kafka"></a> [kube\_storage\_class\_for\_kafka](#input\_kube\_storage\_class\_for\_kafka) | In AKS, we expect to use the 'default' storage class for managed SSD but this could be any storage class you have configured in kubernetes. | `string` | `"default"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| <a name="input_num_kafka_volumes"></a> [num\_kafka\_volumes](#input\_num\_kafka\_volumes) | Kafka brokers will have at least 1 volume. This specifies additional volumes to increase throughput by spreading partitions across multiple disks. | `number` | `1` | no |
| <a name="input_strimzi_operator_chart_version"></a> [strimzi\_operator\_chart\_version](#input\_strimzi\_operator\_chart\_version) | Helm release chart version for Strimzi. | `string` | n/a | yes |
| <a name="input_strimzi_operator_repo"></a> [strimzi\_operator\_repo](#input\_strimzi\_operator\_repo) | Strimzi operator repo. | `string` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_kafka-connection-string"></a> [kafka-connection-string](#output\_kafka-connection-string) | n/a |

<!-- END_K8STRIMZ_MAIN_DOCS -->

<!-- BEGIN_K8LSPR_MAIN_DOCS -->
## Module: kubernetes/logscale-prereqs
This module installs a number of prerequisites for running Logscale in Kubernetes to include:
* Kubernetes Namespaces
* Cert Manager
* Let's Encrypt Issuer manifest
* NGINX Ingress for managing connections to Logscale
* Topo LVM for managing storage on NVME-enabled nodes

Additionally, the module creates a number of kubernetes secrets used by Logscale. This way, you can change/destroy/reapply the Logscale
module without impact to these values.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_keyvault_id"></a> [azure\_keyvault\_id](#input\_azure\_keyvault\_id) | The Azure Keyvault ID storing all the secrets above. | `any` | n/a | yes |
| <a name="input_azure_keyvault_secret_expiration_date"></a> [azure\_keyvault\_secret\_expiration\_date](#input\_azure\_keyvault\_secret\_expiration\_date) | When secrets should expire. | `string` | n/a | yes |
| <a name="input_azure_logscale_ingress_domain_name_label"></a> [azure\_logscale\_ingress\_domain\_name\_label](#input\_azure\_logscale\_ingress\_domain\_name\_label) | The domain name label associated with the public IP resource in var.azure\_logscale\_ingress\_pip\_name | `string` | n/a | yes |
| <a name="input_azure_logscale_ingress_pip_name"></a> [azure\_logscale\_ingress\_pip\_name](#input\_azure\_logscale\_ingress\_pip\_name) | The public IP resource name to pass to Azure for associating with the managed load balancer. | `string` | n/a | yes |
| <a name="input_azure_storage_acct_kv_name"></a> [azure\_storage\_acct\_kv\_name](#input\_azure\_storage\_acct\_kv\_name) | Azure Keyvault item storing the storage access key. | `string` | n/a | yes |
| <a name="input_cert_ca_server"></a> [cert\_ca\_server](#input\_cert\_ca\_server) | Certificate Authority Server. | `string` | n/a | yes |
| <a name="input_cert_issuer_email"></a> [cert\_issuer\_email](#input\_cert\_issuer\_email) | Certificates issuer email for the Logscale Cluster | `string` | n/a | yes |
| <a name="input_cert_issuer_kind"></a> [cert\_issuer\_kind](#input\_cert\_issuer\_kind) | Certificates issuer kind for the Logscale cluster. | `string` | n/a | yes |
| <a name="input_cert_issuer_name"></a> [cert\_issuer\_name](#input\_cert\_issuer\_name) | Certificates issuer name for the Logscale Cluster | `string` | n/a | yes |
| <a name="input_cert_issuer_private_key"></a> [cert\_issuer\_private\_key](#input\_cert\_issuer\_private\_key) | Certificates issuer private key for the Logscale Cluster | `string` | n/a | yes |
| <a name="input_cm_repo"></a> [cm\_repo](#input\_cm\_repo) | The cert-manager repository. | `string` | `"https://charts.jetstack.io"` | no |
| <a name="input_cm_version"></a> [cm\_version](#input\_cm\_version) | The cert-manager helm chart version | `string` | n/a | yes |
| <a name="input_custom_tls_certificate_keyvault_entry"></a> [custom\_tls\_certificate\_keyvault\_entry](#input\_custom\_tls\_certificate\_keyvault\_entry) | The keyvault entry containing the TLS certificate | `string` | `null` | no |
| <a name="input_k8s_config_context"></a> [k8s\_config\_context](#input\_k8s\_config\_context) | Configuration context name, typically the kubernetes server name. | `any` | n/a | yes |
| <a name="input_k8s_config_path"></a> [k8s\_config\_path](#input\_k8s\_config\_path) | The path to k8s configuration. | `any` | n/a | yes |
| <a name="input_k8s_namespace_prefix"></a> [k8s\_namespace\_prefix](#input\_k8s\_namespace\_prefix) | Multiple namespaces will be created to contain resources using this prefix. | `string` | `"log"` | no |
| <a name="input_logscale_cluster_type"></a> [logscale\_cluster\_type](#input\_logscale\_cluster\_type) | Logscale cluster type | `string` | n/a | yes |
| <a name="input_logscale_ingress_data_disk_size"></a> [logscale\_ingress\_data\_disk\_size](#input\_logscale\_ingress\_data\_disk\_size) | The size of the data disk to provision for each ingress pod. (i.e. 20Gi) | `string` | n/a | yes |
| <a name="input_logscale_ingress_max_pod_count"></a> [logscale\_ingress\_max\_pod\_count](#input\_logscale\_ingress\_max\_pod\_count) | The maximum number of ingress pods. | `number` | n/a | yes |
| <a name="input_logscale_ingress_min_pod_count"></a> [logscale\_ingress\_min\_pod\_count](#input\_logscale\_ingress\_min\_pod\_count) | The minimum number of ingress pods. | `number` | n/a | yes |
| <a name="input_logscale_ingress_pod_count"></a> [logscale\_ingress\_pod\_count](#input\_logscale\_ingress\_pod\_count) | The number of ingress pods to start with. | `number` | n/a | yes |
| <a name="input_logscale_ingress_resources"></a> [logscale\_ingress\_resources](#input\_logscale\_ingress\_resources) | The resource requests and limits for cpu and memory to apply ingress pods formatted in a json map. Example: {"limits": {"cpu": 2, "memory": "2Gi"}, "requests": {"cpu": 2, "memory": "2Gi"}} | `map` | n/a | yes |
| <a name="input_logscale_lb_internal_only"></a> [logscale\_lb\_internal\_only](#input\_logscale\_lb\_internal\_only) | The nginx ingress controller to logscale will create a managed azure load balancer. This can be public or private. Set this to false to make it public. | `bool` | n/a | yes |
| <a name="input_logscale_license"></a> [logscale\_license](#input\_logscale\_license) | Your logscale license. | `string` | n/a | yes |
| <a name="input_logscale_public_fqdn"></a> [logscale\_public\_fqdn](#input\_logscale\_public\_fqdn) | The FQDN tied to the public IP address for logscale ingress. This is the resource that will have a certificate provisioned from let's encrypt. | `string` | n/a | yes |
| <a name="input_logscale_public_ip"></a> [logscale\_public\_ip](#input\_logscale\_public\_ip) | The public IP address for logscale ingress. | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| <a name="input_nginx_ingress_helm_chart_version"></a> [nginx\_ingress\_helm\_chart\_version](#input\_nginx\_ingress\_helm\_chart\_version) | The version of nginx-ingress to install in the environment. Reference: github.com/kubernetes/ingress-nginx for helm chart version to nginx version mapping. | `string` | n/a | yes |
| <a name="input_password_rotation_arbitrary_value"></a> [password\_rotation\_arbitrary\_value](#input\_password\_rotation\_arbitrary\_value) | This can be any old value and does not factor into password generation. When changed, it will result in a new password being generated and saved to kubernetes secrets. | `string` | `"defaultstring"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The Azure resource group containing the public IP created for the azure load balancer tied to the nginx-ingress resource in this recipe. | `string` | n/a | yes |
| <a name="input_topo_lvm_chart_version"></a> [topo\_lvm\_chart\_version](#input\_topo\_lvm\_chart\_version) | TopoLVM Chart version to use for installation. | `string` | n/a | yes |
| <a name="input_use_custom_certificate"></a> [use\_custom\_certificate](#input\_use\_custom\_certificate) | Use a custom provided certificate on the frontend instead of Let's Encrypt? | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_k8s_secret_encryption_key"></a> [k8s\_secret\_encryption\_key](#output\_k8s\_secret\_encryption\_key) | n/a |
| <a name="output_k8s_secret_logscale_license"></a> [k8s\_secret\_logscale\_license](#output\_k8s\_secret\_logscale\_license) | n/a |
| <a name="output_k8s_secret_static_user_logins"></a> [k8s\_secret\_static\_user\_logins](#output\_k8s\_secret\_static\_user\_logins) | n/a |
| <a name="output_k8s_secret_storage_access_key"></a> [k8s\_secret\_storage\_access\_key](#output\_k8s\_secret\_storage\_access\_key) | n/a |
| <a name="output_k8s_secret_user_tls_cert"></a> [k8s\_secret\_user\_tls\_cert](#output\_k8s\_secret\_user\_tls\_cert) | n/a |

<!-- END_K8LSPR_MAIN_DOCS -->

<!-- BEGIN_K8LS_MAIN_DOCS -->
## Module: kubernetes/logscale
This module provisions the Humio Operator in the target kubernetes environment and installs manifests that instruct the Humio Operator
on the Logscale cluster to build. This also controls creation of ingress points for the nginx-ingress controllers to route traffic
to Logscale systems.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_storage_account_name"></a> [azure\_storage\_account\_name](#input\_azure\_storage\_account\_name) | Storage account name where logscale will connect for object storage. | `string` | n/a | yes |
| <a name="input_azure_storage_container_name"></a> [azure\_storage\_container\_name](#input\_azure\_storage\_container\_name) | Storage container within the account identified by var.azure\_storage\_account\_name where data will be stored. | `string` | n/a | yes |
| <a name="input_azure_storage_endpoint_base"></a> [azure\_storage\_endpoint\_base](#input\_azure\_storage\_endpoint\_base) | Connection endpoint for the azure storage bucket. | `string` | n/a | yes |
| <a name="input_cert_issuer_name"></a> [cert\_issuer\_name](#input\_cert\_issuer\_name) | Certificates issuer name for the Logscale Cluster | `string` | n/a | yes |
| <a name="input_enable_intracluster_tls"></a> [enable\_intracluster\_tls](#input\_enable\_intracluster\_tls) | Controls use of TLS between cluster components. Default: true. Can be useful to turn off when testing. | `bool` | `true` | no |
| <a name="input_humio_operator_chart_version"></a> [humio\_operator\_chart\_version](#input\_humio\_operator\_chart\_version) | This is the version of the helm chart that installs the humio operator version chosen in variable humio\_operator\_version. | `string` | n/a | yes |
| <a name="input_humio_operator_extra_values"></a> [humio\_operator\_extra\_values](#input\_humio\_operator\_extra\_values) | Resource Management for logscale pods | `map(string)` | n/a | yes |
| <a name="input_humio_operator_repo"></a> [humio\_operator\_repo](#input\_humio\_operator\_repo) | The humio operator repository. | `string` | `"https://humio.github.io/humio-operator"` | no |
| <a name="input_humio_operator_version"></a> [humio\_operator\_version](#input\_humio\_operator\_version) | The humio operator controls provisioning of logscale resources within kubernetes. | `string` | n/a | yes |
| <a name="input_image_pull_secret"></a> [image\_pull\_secret](#input\_image\_pull\_secret) | The kubernetes secret containing credentials to access the image repository. Required when setting logscale\_image. | `string` | `"regcred"` | no |
| <a name="input_k8s_config_context"></a> [k8s\_config\_context](#input\_k8s\_config\_context) | Configuration context name, typically the kubernetes server name. | `string` | n/a | yes |
| <a name="input_k8s_config_path"></a> [k8s\_config\_path](#input\_k8s\_config\_path) | The path to k8s configuration. | `string` | n/a | yes |
| <a name="input_k8s_namespace_prefix"></a> [k8s\_namespace\_prefix](#input\_k8s\_namespace\_prefix) | Multiple namespaces will be created to contain resources using this prefix. | `string` | `"log"` | no |
| <a name="input_k8s_secret_encryption_key"></a> [k8s\_secret\_encryption\_key](#input\_k8s\_secret\_encryption\_key) | The k8s secret containing the logscale storage encryption key value. | `string` | n/a | yes |
| <a name="input_k8s_secret_logscale_license"></a> [k8s\_secret\_logscale\_license](#input\_k8s\_secret\_logscale\_license) | The k8s secret containing the logscale license. | `string` | n/a | yes |
| <a name="input_k8s_secret_static_user_logins"></a> [k8s\_secret\_static\_user\_logins](#input\_k8s\_secret\_static\_user\_logins) | The k8s secret containing that static user logon list | `string` | n/a | yes |
| <a name="input_k8s_secret_storage_access_key"></a> [k8s\_secret\_storage\_access\_key](#input\_k8s\_secret\_storage\_access\_key) | The k8s secret containing the azure bucket storage access key. | `string` | n/a | yes |
| <a name="input_k8s_secret_user_tls_cert"></a> [k8s\_secret\_user\_tls\_cert](#input\_k8s\_secret\_user\_tls\_cert) | The k8s secret containing the user provided TLS cert for logscale | `string` | `null` | no |
| <a name="input_kafka_broker_servers"></a> [kafka\_broker\_servers](#input\_kafka\_broker\_servers) | Kafka connection string used by logscale. | `string` | n/a | yes |
| <a name="input_kube_storage_class_for_logscale"></a> [kube\_storage\_class\_for\_logscale](#input\_kube\_storage\_class\_for\_logscale) | Kubernetes storage class to use when provisioning persistent claims for digest nodes. | `string` | `"topolvm-provisioner"` | no |
| <a name="input_kube_storage_class_for_logscale_ingest"></a> [kube\_storage\_class\_for\_logscale\_ingest](#input\_kube\_storage\_class\_for\_logscale\_ingest) | In AKS, we expect to use the 'default' storage class for managed SSD but this could be any storage class you have configured in kubernetes. | `string` | `"default"` | no |
| <a name="input_kube_storage_class_for_logscale_ui"></a> [kube\_storage\_class\_for\_logscale\_ui](#input\_kube\_storage\_class\_for\_logscale\_ui) | In AKS, we expect to use the 'default' storage class for managed SSD but this could be any storage class you have configured in kubernetes. | `string` | `"default"` | no |
| <a name="input_logscale_cluster_type"></a> [logscale\_cluster\_type](#input\_logscale\_cluster\_type) | Logscale cluster type | `string` | n/a | yes |
| <a name="input_logscale_digest_data_disk_size"></a> [logscale\_digest\_data\_disk\_size](#input\_logscale\_digest\_data\_disk\_size) | n/a | `any` | n/a | yes |
| <a name="input_logscale_digest_pod_count"></a> [logscale\_digest\_pod\_count](#input\_logscale\_digest\_pod\_count) | Resources for digest nodes | `any` | n/a | yes |
| <a name="input_logscale_digest_resources"></a> [logscale\_digest\_resources](#input\_logscale\_digest\_resources) | n/a | `any` | n/a | yes |
| <a name="input_logscale_image"></a> [logscale\_image](#input\_logscale\_image) | This can be used to specify a full image ref spec. The expectation is that the imagePullSecrets kubernetes secret will exist. | `string` | `null` | no |
| <a name="input_logscale_image_version"></a> [logscale\_image\_version](#input\_logscale\_image\_version) | The version of logscale to install. | `string` | `""` | no |
| <a name="input_logscale_ingest_data_disk_size"></a> [logscale\_ingest\_data\_disk\_size](#input\_logscale\_ingest\_data\_disk\_size) | n/a | `any` | n/a | yes |
| <a name="input_logscale_ingest_pod_count"></a> [logscale\_ingest\_pod\_count](#input\_logscale\_ingest\_pod\_count) | Resources for ingest nodes | `any` | n/a | yes |
| <a name="input_logscale_ingest_resources"></a> [logscale\_ingest\_resources](#input\_logscale\_ingest\_resources) | n/a | `any` | n/a | yes |
| <a name="input_logscale_public_fqdn"></a> [logscale\_public\_fqdn](#input\_logscale\_public\_fqdn) | The FQDN tied to the public IP address for logscale ingress. This is the resource that will have a certificate provisioned from let's encrypt. | `string` | n/a | yes |
| <a name="input_logscale_ui_data_disk_size"></a> [logscale\_ui\_data\_disk\_size](#input\_logscale\_ui\_data\_disk\_size) | n/a | `any` | n/a | yes |
| <a name="input_logscale_ui_pod_count"></a> [logscale\_ui\_pod\_count](#input\_logscale\_ui\_pod\_count) | n/a | `any` | n/a | yes |
| <a name="input_logscale_ui_resources"></a> [logscale\_ui\_resources](#input\_logscale\_ui\_resources) | Resources for ui/query coordinator nodes | `any` | n/a | yes |
| <a name="input_logscale_update_strategy"></a> [logscale\_update\_strategy](#input\_logscale\_update\_strategy) | When describing a HumioCluster resource, you can provide a map value to describe how updates should be applied. Defaults to RollingUpdateBestEffort, 50% maximum unavailable, zone awareness enabled. | `map` | <pre>{<br/>  "enableZoneAwareness": true,<br/>  "maxUnavailable": "50%",<br/>  "minReadySeconds": 120,<br/>  "type": "RollingUpdateBestEffort"<br/>}</pre> | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Identifier attached to named resources to help them stand out. | `string` | n/a | yes |
| <a name="input_provision_kafka_servers"></a> [provision\_kafka\_servers](#input\_provision\_kafka\_servers) | Set this to true if we provisioned strimzi kafka servers during this process. | `bool` | n/a | yes |
| <a name="input_target_replication_factor"></a> [target\_replication\_factor](#input\_target\_replication\_factor) | The default replication factor for logscale. | `number` | `2` | no |
| <a name="input_use_custom_certificate"></a> [use\_custom\_certificate](#input\_use\_custom\_certificate) | Use a custom provided certificate on the frontend instead of Let's Encrypt? | `bool` | `false` | no |
| <a name="input_user_logscale_envvars"></a> [user\_logscale\_envvars](#input\_user\_logscale\_envvars) | These are environment variables passed into the HumioCluster resource spec definition that will be used for all created logscale instances. Supports string values and kubernetes secret refs. Will override any values defined by default in the configuration. | <pre>list(object({<br/>    name=string,<br/>    value=optional(string)<br/>    valueFrom=optional(object({<br/>      secretKeyRef = object({<br/>        name = string<br/>        key = string<br/>      })<br/>    }))<br/>  }))</pre> | `[]` | no |

### Outputs

No outputs.

<!-- END_K8LS_MAIN_DOCS -->

# Build Process
1. Create a .tfvars file or modify the provided `example.tfvars` to specify configurations for the environment.
    - Reference section **Terraform Modules** below for a full list of configuration values.
2. Set this file as environment variable TFVAR_FILE
```
export TFVAR_FILE=/path/to/myfile.tfvars
```
3. Login with the Azure Command Line
```
az login
```
4. ***(Optional)*** Create a `backend.tf` definition suitable to your environment. For example, to store state in an Azure blob storage container (created separately):
```hcl
    terraform {
        backend "azurerm" {
            resource_group_name  = "my-resource-group-name"
            storage_account_name = "mystorageaccount"
            container_name       = "mycontainer"
            key                  = "logscale-terraform.tfstate"
        }
    }
```
5. Create a main.tf with the modules necessary to build Logscale in the target environment or leverage a provided quickstart example. By default, this repository links to `examples/full-no-bastion.tf`.
```
ln -s repository-path/examples/full-no-bastion.tf repository-path/main.tf
```
6. Initialize terraform
```
terraform init -upgrade
```
7. Build the Azure infrastructure. This instruction assumes use of the quickstart template `examples/full-no-bastion.tf` and targets need to be updated accordingly when using a different example or self-built modules.
```
terraform apply -target module.azure-core -target module.azure-keyvault -target module.azure-kubernetes -target module.logscale-storage-account -var-file $TFVAR_FILE
```
8. Configure kubectl. The previous command output will show `k8s_configuration_command`, run this command.
```
az aks get-credentials --resource-group ${var.name_prefix}-rg --name aks-${var.name_prefix}
```
9. Apply custom resource definitions to Kubernetes
```
terraform apply -target module.crds -var-file $TFVAR_FILE
```
10. Run the logscale prerequisites module to prepare the environment for Logscale
```
terraform apply -target module.logscale-prereqs -var-file $TFVAR_FILE
```
11. Install Strimzi
```
terraform apply -target module.kafka -var-file $TFVAR_FILE
```
12. Install the Humio Operator and Logscale cluster definitions
```
terraform apply -target module.logscale -var-file $TFVAR_FILE
```
# Support
LogScale Reference Automations for Azure (logscale-azure) is an open source project, not a CrowdStrike product. As such, it carries no formal support, expressed or implied.

# References
- [Cert Manager Documentation](https://cert-manager.io/docs/)
- [Strimzi Documentation](https://strimzi.io/documentation/)
- [NGINX Ingress Controller Documentation](https://docs.nginx.com/nginx-ingress-controller/)
- [NGINX Ingress Configuration in Azure](https://learn.microsoft.com/en-us/azure/aks/app-routing-nginx-configuration?tabs=azurecli)
- [Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/)
- [Humio Operator](https://github.com/humio/humio-operator)
