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

    template = {
      source = "hashicorp/template"
    }
    rancher2 = {
      source = "rancher/rancher2"
    }
    cloudscale = {
      source = "cloudscale-ch/cloudscale"
    }

  }
  required_version = ">= 1.3.3"
}
