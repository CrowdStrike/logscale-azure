/**
 * ## Module: azure/certificate
 * An optional module that can be used to provision a certificate within Azure KeyVault. This is expected to be used for self-signed
 * test certificates but depending on the configuration of your KeyVault, it can be leveraged to provsion valid certs.
 * 
 */
resource "azurerm_key_vault_certificate" "logscale-fqdn-cert" {
    name                        = "${var.name_prefix}-tls-cert"
    key_vault_id                = var.azure_keyvault_id

    certificate_policy {
        issuer_parameters {  
            name                   = var.cert_issuer
        }
        
        key_properties {
            exportable              = true
            key_size                = 4096
            key_type                = "RSA"
            reuse_key               = true
        }

        lifetime_action {
            action {
                action_type         = "AutoRenew"
            }

            trigger {
                days_before_expiry  = 30
            }
        }

        secret_properties {
            content_type            = "application/x-pem-file"
        }

        x509_certificate_properties {
            extended_key_usage      = ["1.3.6.1.5.5.7.3.1"]

            key_usage               = [ "cRLSign", "dataEncipherment", "digitalSignature", "keyAgreement", "keyCertSign", "keyEncipherment" ]
        

            subject_alternative_names {
                dns_names               = length(var.subject_alternative_names)>0 ? var.subject_alternative_names : [ var.logscale_public_fqdn ]
            }

            subject                     = "CN=${var.logscale_public_fqdn}"
            validity_in_months          = 12
        }
    }

}