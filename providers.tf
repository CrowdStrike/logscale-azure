terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
      version = "~>1.5"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.21.0"
    }

    random = {
      source = "hashicorp/random"
      version = ">=3.6.1"
    }

    time = {
      source = "hashicorp/time"
      version = ">=0.9.1"
    }

    http = {
      source = "hashicorp/http"
      version = "~>3.4.2"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">=2.31.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">=3.2"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">=2.13.2,<3.0.0"
    }

  }
}


provider "azurerm" {
  subscription_id     = var.azure_subscription_id
  environment         = var.azure_environment    
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "tls" {}