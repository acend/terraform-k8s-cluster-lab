terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    k8s = {
      source = "banzaicloud/k8s"
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
      source  = "hetznercloud/hcloud"
      version = "1.36.2"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.6.0"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "1.18.0"
    }

  }
  required_version = ">= 1.3.3"
}
