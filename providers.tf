
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

# Kubernetes provider for logscale-kubernetes module
# Uses kubeconfig approach for simplicity and consistency with logscale-kubernetes
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Helm provider for logscale-kubernetes module
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
