terraform {
  backend "remote" {}
}

module "training-cluster" {
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

  # Gitea
  gitea-enabled = var.gitea-enabled

  # User VMs
  user-vms-enabled = var.user-vms-enabled

  # RBAC in Webshell
  webshell-rbac-enabled = var.webshell-rbac-enabled

  # Persistence in Theia and DinD
  dind-persistence-enabled  = var.dind-persistence-enabled
  theia-persistence-enabled = var.theia-persistence-enabled
}
