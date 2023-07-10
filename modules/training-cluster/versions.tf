terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    local = {
      source = "hashicorp/local"
    }
    template = {
      source = "hashicorp/template"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    ssh = {
      source = "loafoe/ssh"
    }
    restapi = {
      source = "Mastercard/restapi"
    }
  }
  required_version = ">= 1.3.3"
}
