
output "storage_acct_id" {
    value = azurerm_storage_account.storage-account.id
}

output "storage_acct_name" {
    value = azurerm_storage_account.storage-account.name
}

output "storage_acct_container_name" {
    value = try(azurerm_storage_container.storage-account-container[0].name,null)
}

output "storage_acct_container_id" {
    value = try(azurerm_storage_container.storage-account-container[0].id,null)
}

output "storage_acct_access_key_kv" {
    value = azurerm_key_vault_secret.storage-account-access-secret.name
}

output "storage_acct_blob_endpoint" {
    value = azurerm_storage_account.storage-account.primary_blob_endpoint
}