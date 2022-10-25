# Deploy Cert-Manager for Certificates
module "cert-manager" {
  source = "./modules/cert-manager"

  depends_on = [rancher2_cluster_sync.training]

  letsencrypt_email      = var.letsencrypt_email
  rancher_system_project = data.rancher2_project.system

  acme-config = var.acme-config
}