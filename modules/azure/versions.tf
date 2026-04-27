terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.26"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.3"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
    terracurl = {
      source  = "devops-rob/terracurl"
      version = ">= 1.2.1"
    }
  }
  required_version = ">= 1.9.8"
}
