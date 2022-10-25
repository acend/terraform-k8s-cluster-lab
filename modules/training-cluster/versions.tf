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
    cloudscale = {
      source = "cloudscale-ch/cloudscale"
      // The version attribute can be used to pin to a specific version
      //version = "~> 3.0.0"
    }

  }
  required_version = ">= 1.2.4"
}
