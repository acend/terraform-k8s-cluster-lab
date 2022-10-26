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
      version = "1.24.2"
    }
    template = {
      source = "hashicorp/template"
    }
    cloudscale = {
      source = "cloudscale-ch/cloudscale"
    }

  }
  required_version = ">= 1.3.3"
}
