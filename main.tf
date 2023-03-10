module "training-cluster" {
  source = "./modules/training-cluster"

  first_install = true

  k8s_api_hostnames = ["api.labcluster.acend.ch"]
  cluster_name       = var.cluster_name

  hcloud_api_token     = var.hcloud_api_token
  hosttech_dns_token   = var.hosttech_dns_token
  hosttech-dns-zone-id = var.hosttech-dns-zone-id

  controlplane_type = var.controlplane_type
  worker_type       = var.worker_type
  worker_count      = var.worker_count
  extra_ssh_keys    = var.extra_ssh_keys

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
