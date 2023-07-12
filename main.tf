terraform {
  backend "remote" {}
}

provider "hcloud" {
  token = var.hcloud_api_token
}

provider "restapi" {
  alias                = "hosttech_dns"
  uri                  = "https://api.ns1.hosttech.eu"
  write_returns_object = true

  headers = {
    Authorization = "Bearer ${var.hosttech_dns_token}"
    ContentType   = "application/json"
  }
}

module "training-cluster" {

  providers = {
    restapi.hosttech_dns = restapi.hosttech_dns
    hcloud               = hcloud
  }

  source = "./modules/training-cluster"

  first_install = true

  cluster_name   = var.cluster_name
  cluster_domain = var.cluster_domain

  hcloud_api_token     = var.hcloud_api_token
  hosttech_dns_token   = var.hosttech_dns_token
  hosttech-dns-zone-id = var.hosttech-dns-zone-id

  worker_count   = var.worker_count
  extra_ssh_keys = var.extra_ssh_keys

  cluster_admin = var.cluster_admin

  # Webshell
  count-students = var.count-students

  # User VMs
  user-vms-enabled = var.user-vms-enabled

  # RBAC in Webshell
  webshell-rbac-enabled = var.webshell-rbac-enabled

  # Persistence in Theia and DinD
  dind-persistence-enabled  = var.dind-persistence-enabled
  theia-persistence-enabled = var.theia-persistence-enabled
}
