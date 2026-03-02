# Azure storage secret for LogScale
# This is deployed AFTER logscale-prereqs creates the namespace
# Usage: terraform apply -target="kubernetes_secret_v1.azure_storage_key"

resource "kubernetes_secret_v1" "azure_storage_key" {
  metadata {
    name      = "azure-storage-key"
    namespace = var.logscale_cluster_k8s_namespace_name
  }

  data = {
    "storage-access-key" = data.azurerm_key_vault_secret.storage_access_key.value
  }

  depends_on = [
    data.azurerm_key_vault_secret.storage_access_key
  ]
}