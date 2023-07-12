terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source                = "hashicorp/kubernetes"
      configuration_aliases = [kubernetes.local, kubernetes.acend]
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
      source                = "Mastercard/restapi"
      configuration_aliases = [restapi.hosttech_dns]
    }
  }
  required_version = ">= 1.3.3"
}
