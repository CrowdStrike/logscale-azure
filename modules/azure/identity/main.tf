
/**
 * ## Module: azure/identity
 * This optional module can be used to provision a managed identity in Azure and assign a role to the identity.
 *
 */
data "azurerm_subscription" "current" {}


resource "azurerm_user_assigned_identity" "identity" {
    location                            = var.resource_group_region
    resource_group_name                 = var.resource_group_name

    name                                = "ident-${var.name_prefix}"

    tags                                = var.tags
}

resource "azurerm_role_assignment" "role_assign" {
    scope                               = data.azurerm_subscription.current.id
    role_definition_name                = var.role_definition_name
    principal_id                        = azurerm_user_assigned_identity.identity.principal_id
    skip_service_principal_aad_check    = true
}