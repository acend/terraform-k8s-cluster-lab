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
}

locals {
  argocd_enabled = var.argocd-enabled ? 1 : 0
  gitea_enabled  = var.gitea-enabled ? 1 : 0
  vms-enabled    = var.user-vms-enabled ? 1 : 0
  hasWorker      = var.worker_count > 0 ? 1 : 0
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


# Deploy Webshell with a student Namespace to work in 
module "webshell" {
  source = "./modules/webshell"

  depends_on = [
    time_sleep.wait_for_cluster_ready,
    module.student-vms
  ]

  cluster_name       = var.cluster_name
  cluster_domain     = var.cluster_domain

  student-index            = count.index
  student-name             = "${var.studentname-prefix}${count.index + 1}"
  student-password         = random_password.student-passwords[count.index].result

  user-vm-enabled = var.user-vms-enabled
  student-vms     = var.user-vms-enabled ? [module.student-vms[0]] : null
  rbac-enabled    = var.webshell-rbac-enabled

  count = var.count-students
}

module "student-vms" {
  source = "./modules/student-vms"

  cluster_name = var.cluster_name

  count-students     = var.count-students
  student-passwords  = random_password.student-passwords
  studentname-prefix = var.studentname-prefix

  extra_ssh_keys = var.extra_ssh_keys

  count = local.vms-enabled

}


# Deploy ArgoCD and configure it for the students
module "argocd" {
  source = "./modules/argocd"

  cluster_name       = var.cluster_name
  cluster_domain     = var.cluster_domain
  count-students     = var.count-students
  student-passwords  = random_password.student-passwords
  studentname-prefix = var.studentname-prefix

  kubeconfig_raw = local.kubeconfig_raw

  count = local.argocd_enabled

  depends_on = [
    time_sleep.wait_for_cluster_ready,
    module.webshell // student namespaces are created in the webshell module
  ]
}

# Deploy Gitea and configure it for the students
module "gitea" {
  source = "./modules/gitea"

  cluster_name       = var.cluster_name
  cluster_domain     = var.cluster_domain
  count-students     = var.count-students
  student-passwords  = random_password.student-passwords
  studentname-prefix = var.studentname-prefix


  count = local.gitea_enabled

  depends_on = [
     time_sleep.wait_for_cluster_ready
  ]
}
