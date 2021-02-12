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
    rancher2 = {
      source = "rancher/rancher2"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
}
