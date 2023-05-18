terraform {
  required_providers {

    hcloud = {
      source = "hetznercloud/hcloud"
    }
    template = {
      source = "hashicorp/template"
    }

  }
  required_version = ">= 1.3.3"
}
