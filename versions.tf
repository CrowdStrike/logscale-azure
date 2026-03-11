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
    null = {
      source  = "hashicorp/null"
      version = ">=3.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.38.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">=2.17.0"
    }
  }
  
}