terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
  #  virtual_machine {
  #    graceful_shutdown = true
  #  }
  }
}

provider "helm" {
  kubernetes {
    config_path = local_file.kubeconfig.filename
  }
}
