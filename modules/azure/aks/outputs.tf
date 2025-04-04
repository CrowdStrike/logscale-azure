
# Kubernetes information
output "k8s_cluster_principal_id" {
  value = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
}

output "k8s_cluster_name" {
  value = azurerm_kubernetes_cluster.k8s.name
}

output "k8s_cluster_endpoint" {
  value = azurerm_kubernetes_cluster.k8s.kube_config.0.host
}

output "k8s_cluster_id" {
  value = azurerm_kubernetes_cluster.k8s.id
}

output "k8s_kube_config_kv_name" {
  value = azurerm_key_vault_secret.kube-config.name
}
output "k8s_client_certificate_kv_name" {
  value = azurerm_key_vault_secret.client-cert.name
}
output "k8s_client_key_kv_name" {
  value = azurerm_key_vault_secret.client-key.name
}
output "k8s_cluster_ca_certificate_kv_name" {
  value = azurerm_key_vault_secret.cluster-ca-cert.name
}