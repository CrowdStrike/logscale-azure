
output "keyvault_id" {
    value = azurerm_key_vault.logscale-keyvault.id

    # We need to make sure modules relying on the KV to be created do not try to move forward with anything unless this access is provisioned.
    depends_on = [ azurerm_key_vault_access_policy.default-kv-access ]
}

output "keyvault_name" {
    value = azurerm_key_vault.logscale-keyvault.name

    # We need to make sure modules relying on the KV to be created do not try to move forward with anything unless this access is provisioned.
    depends_on = [ azurerm_key_vault_access_policy.default-kv-access ]
}