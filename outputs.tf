


output "k8s_configuration_command" {
    description = "Run this command after building the kubernetes cluster to set your local kube config"
    value = "az aks get-credentials --resource-group ${local.resource_name_prefix}-rg --name aks-${local.resource_name_prefix}"
}

# Kubernetes information
output "k8s_cluster_context" {
    value = try(module.azure-kubernetes.k8s_cluster_name, null)
}

output "k8s_cluster_name" {
    value = try(module.azure-kubernetes.k8s_cluster_name, null)
}

output "logscale_cluster_type" {
    value = var.logscale_cluster_type
}

output "logscale_cluster_size" {
    value = var.logscale_cluster_size
}

output "logscale_public_fqdn" {
    value = try(module.azure-core.ingress-pub-fqdn, null)
    description = "Public FQDN for access to logscale environment via Azure LB, when public access is enabled"
}

output "controller_service_loadBalancerIP" {
    value = try(module.azure-core.ingress-pub-ip, null)
    description = "Public IP address for access to logscale environment via Azure LB, when public access is enabled"
}

output "azure-load-balancer-resource-group" {
    value = try(module.azure-core.resource_group_name, null)
}

output "azure-pip-name" {
  value = module.azure-core.ingress-pub-pip-name
}

output "azure-dns-label-name" {
  value = module.azure-core.ingress-pup-pip-domain-name-label
}

output "AZURE_STORAGE_ACCOUNTNAME" {
  value = module.logscale-storage-account.storage_acct_name
}                   
output "AZURE_STORAGE_BUCKET" {
  value = module.logscale-storage-account.storage_acct_container_name
}
output "AZURE_STORAGE_ENDPOINT_BASE" {
  value = module.logscale-storage-account.storage_acct_blob_endpoint
}

output "AZURE_STORAGE_OBJECT_KEY_PREFIX" {
    value = local.resource_name_prefix
    description = "Prefix added to resources for unique identification"
}