
terraform {
  backend "remote" {}
}

module "training-cluster" {
  source = "./modules/training-cluster"

  cluster_name = var.cluster_name
  domain       = var.domain

  rancher2_access_key  = var.rancher2_access_key
  rancher2_secret_key  = var.rancher2_secret_key
  rancher2_api_url     = var.rancher2_api_url
  cloudscale_token     = var.cloudscale_token
  hosttech_dns_token   = var.hosttech_dns_token
  hosttech-dns-zone-id = var.hosttech-dns-zone-id
  cluster_owner_group  = var.cluster_owner_group
  node_flavor_master   = var.node_flavor_master
  node_flavor_worker   = var.node_flavor_worker
  node_count_master    = var.node_count_master
  node_count_worker    = var.node_count_worker
  ssh_keys             = var.ssh_keys



  # Webshell
  count-students = var.count-students

  # Argocd
  argocd-enabled = var.argocd-enabled

  # Gitea
  gitea-enabled = var.gitea-enabled

  # User VMs
  user-vms-enabled = var.user-vms-enabled

  # RBAC in Webshell
  webshell-rbac-enabled = var.webshell-rbac-enabled
}
