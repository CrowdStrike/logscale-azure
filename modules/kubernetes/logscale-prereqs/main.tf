/** 
 * ## Module: kubernetes/logscale-prereqs
 * This module installs a number of prerequisites for running Logscale in Kubernetes to include:
 * * Kubernetes Namespaces
 * * Cert Manager
 * * Let's Encrypt Issuer manifest
 * * NGINX Ingress for managing connections to Logscale
 * * Topo LVM for managing storage on NVME-enabled nodes
 * 
 * Additionally, the module creates a number of kubernetes secrets used by Logscale. This way, you can change/destroy/reapply the Logscale
 * module without impact to these values.
 * 
 */
# Get storage access key from key vault
data "azurerm_key_vault_secret" "azure_storage_acct_key" {
    name                    = var.azure_storage_acct_kv_name
    key_vault_id            = var.azure_keyvault_id

}

# get certificate from key vault if a custom TLS certificate is in use
data "azurerm_key_vault_certificate_data" "custom_tls_certificate" {
  count                     = var.use_custom_certificate ? 1 : 0
  
  name                      = var.custom_tls_certificate_keyvault_entry
  key_vault_id              = var.azure_keyvault_id
}

/* Create required namespaces */
resource "kubernetes_namespace" "logscale" {
  metadata {
    name = "${var.k8s_namespace_prefix}"
  }
}

resource "kubernetes_namespace" "logscale-ingress" {
  metadata {
    name = "${var.k8s_namespace_prefix}-ingress"
  }
}

resource "kubernetes_namespace" "logscale-topo" {
  metadata {
    name = "${var.k8s_namespace_prefix}-topolvm"
  }
}

resource "kubernetes_namespace" "cert_manager" {
  #count                     = var.use_custom_certificate ? 0 : 1
  count                     = 1
  metadata {
    name = "${var.k8s_namespace_prefix}-cert"
  }
}


