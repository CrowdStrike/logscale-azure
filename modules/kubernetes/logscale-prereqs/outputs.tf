
output "k8s_secret_static_user_logins" {
    value = kubernetes_secret.static_user_logins.metadata[0].name
}

output "k8s_secret_logscale_license" {
    value = kubernetes_secret.logscale_license.metadata[0].name
}

output "k8s_secret_encryption_key" {
    value = kubernetes_secret.storage_encryption_key.metadata[0].name
}

output "k8s_secret_storage_access_key" {
    value = kubernetes_secret.storage_access_key.metadata[0].name
}

output "k8s_secret_user_tls_cert" {
    value = var.use_custom_certificate ? kubernetes_secret.user-provided-certificate[0].metadata[0].name : null
}