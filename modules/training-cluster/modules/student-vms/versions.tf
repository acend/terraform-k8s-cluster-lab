terraform {
  required_providers {

    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.36.2"
    }
    template = {
      source = "hashicorp/template"
    }

  }
  required_version = ">= 1.3.3"
}
