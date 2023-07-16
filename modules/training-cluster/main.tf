provider "kubernetes" {

  alias = "local"
  host                   = local.kubernetes_api
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  cluster_ca_certificate = local.cluster_ca_certificate

}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_api
    client_certificate     = local.client_certificate
    client_key             = local.client_key
    cluster_ca_certificate = local.cluster_ca_certificate
  }
}

locals {
  vms-enabled = var.user-vms-enabled ? 1 : 0
  hasWorker   = var.worker_count > 0 ? 1 : 0
}

resource "random_password" "rke2_cluster_secret" {
  length  = 256
  special = false
}

# Create Passwords for the students (shared by multiple apps like webshell, argocd and gitea)
resource "random_password" "student-passwords" {
  length           = 16
  special          = true
  override_special = ".-_"

  count = var.count-students
}

module "student-vms" {
  source = "./modules/student-vms"

  cluster_name = var.cluster_name

  count-students     = var.count-students
  student-passwords  = random_password.student-passwords
  studentname-prefix = var.studentname-prefix

  ssh_key = hcloud_ssh_key.terraform.name

  count = local.vms-enabled

}