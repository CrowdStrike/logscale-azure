# Create kubernetes secrets used by logscale
resource "random_password" "single_user_password" {
  length  = 48
  special = false

  keepers = {
    "random-value" = var.password_rotation_arbitrary_value
  }
}

# Create a secret for the user list
resource "kubernetes_secret" "static_user_logins" {
  metadata {
    name      = "${var.name_prefix}-static-users"
    namespace = resource.kubernetes_namespace.logscale.metadata[0].name
  }
  data = {
    users = "admin:${random_password.single_user_password.result}"
  }
}

resource "kubernetes_secret" "logscale_license" {
  metadata {
    name      = "${var.name_prefix}-license"
    namespace = resource.kubernetes_namespace.logscale.metadata[0].name
  }
  data = {
    humio-license-key = var.logscale_license
  }
}

# This is here to store the logscale_public_fqdn value for use with the ingest-testing module later. 
resource "kubernetes_secret" "logscale_endpoint" {
  metadata {
    name      = "${var.name_prefix}-logscale-endpoint"
    namespace = resource.kubernetes_namespace.logscale.metadata[0].name
  }
  data = {
    value = var.logscale_public_fqdn
  }
}

# The encryption key given with AZURE_STORAGE_ENCRYPTION_KEY can be any UTF-8 string and will
# be used to encrypt the data stored within the bucket. The suggested value is 64 or more random ASCII characters.
# This encryption is applied prior to bucket upload.
resource "random_password" "encryption_password" {
  length  = 64
  special = false
}

resource "kubernetes_secret" "storage_encryption_key" {
  metadata {
    name      = "${var.name_prefix}-storage-encryption"
    namespace = resource.kubernetes_namespace.logscale.metadata[0].name
  }

  data = {
    storage-encryption-key = random_password.encryption_password.result
  }
}

resource "kubernetes_secret" "storage_access_key" {
  metadata {
    name      = "${var.name_prefix}-storage-access-key"
    namespace = resource.kubernetes_namespace.logscale.metadata[0].name
  }
  
  data = {
    storage-access-key = data.azurerm_key_vault_secret.azure_storage_acct_key.value
  }
}

# Store the custom certificate information, if it was provided by the user
resource "kubernetes_secret" "user-provided-certificate" {
  count = var.use_custom_certificate ? 1 : 0

  metadata {
    name          = "${var.name_prefix}-tls-certificate"
    namespace     = resource.kubernetes_namespace.logscale.metadata[0].name
  }

  data = {
    "tls.crt"     = data.azurerm_key_vault_certificate_data.custom_tls_certificate[0].pem
    "tls.key"     = data.azurerm_key_vault_certificate_data.custom_tls_certificate[0].key
  }

  type = "kubernetes.io/tls"
}

# The generated logscale user password needs to be stored in Azure Keyvault
resource "azurerm_key_vault_secret" "logscale-user-password" {
  name                                = "${var.name_prefix}-logscale-user-password"
  key_vault_id                        = var.azure_keyvault_id
  value                               = random_password.single_user_password.result

  expiration_date                     = var.azure_keyvault_secret_expiration_date
  content_type                         = "password"
}

# The data encryption key should be stored in Azure Keyvault as well
# If something happens to kubernetes or the secret is lost, this can be used in the recovery process
resource "azurerm_key_vault_secret" "logscale-encryption-key" {
  name                                = "${var.name_prefix}-logscale-encryption-key"
  key_vault_id                        = var.azure_keyvault_id
  value                               = random_password.encryption_password.result

  expiration_date                     = var.azure_keyvault_secret_expiration_date
  content_type                         = "password"
}
