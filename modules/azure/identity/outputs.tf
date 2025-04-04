output "managed_identity_resource_id" {
    value = azurerm_user_assigned_identity.identity.id
}

output "managed_identity_resource_principal_id" {
    value = azurerm_user_assigned_identity.identity.principal_id
}