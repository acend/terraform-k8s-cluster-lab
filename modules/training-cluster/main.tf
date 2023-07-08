provider "hcloud" {
  token = var.hcloud_api_token
}

provider "kubernetes" {
  # On initial deploy, use this to get the credentials via ssh from rke2
  # Afterwards, update variables and change to them
  host                   = local.kubernetes_api
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  cluster_ca_certificate = local.cluster_ca_certificate

  # host                   = var.provider-k8s-api-host
  # client_certificate     = base64decode(var.provider-client-certificate)
  # client_key             = base64decode(var.provider-client-key)
  # cluster_ca_certificate = base64decode(var.provider-cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    # On initial deploy, use this to get the credentials via ssh from rke2
    # Afterwards, update variables and change to them
    host                   = local.kubernetes_api
    client_certificate     = local.client_certificate
    client_key             = local.client_key
    cluster_ca_certificate = local.cluster_ca_certificate

    # host                   = var.provider-k8s-api-host
    # client_certificate     = base64decode(var.provider-client-certificate)
    # client_key             = base64decode(var.provider-client-key)
    # cluster_ca_certificate = base64decode(var.provider-cluster_ca_certificate)

  }
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

provider "banzaicloud-k8s" {
  host                   = local.kubernetes_api
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  cluster_ca_certificate = local.cluster_ca_certificate
  load_config_file       = false
}

locals {
  vms-enabled   = var.user-vms-enabled ? 1 : 0
  hasWorker     = var.worker_count > 0 ? 1 : 0
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