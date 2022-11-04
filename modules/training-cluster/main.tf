
provider "rancher2" {
  api_url    = var.rancher2_api_url
  access_key = var.rancher2_access_key
  secret_key = var.rancher2_secret_key
}

provider "cloudscale" {
  token = var.cloudscale_token
}

provider "k8s" {
  #config_path = "${path.module}/output/kube.config"
  host             = local.kube_host
  token            = local.kube_token
  load_config_file = "false"
}

provider "kubernetes" {
  host  = local.kube_host
  token = local.kube_token
}


provider "helm" {
  kubernetes {
    #config_path = "${path.module}/output/kube.config"
    host  = local.kube_host
    token = local.kube_token
  }
}


locals {
  kube_config    = yamldecode(rancher2_cluster_sync.training.kube_config)
  kube_host      = local.kube_config.clusters[0].cluster.server
  kube_token     = local.kube_config.users[0].user.token
  argocd_enabled = var.argocd-enabled ? 1 : 0
  gitea_enabled  = var.gitea-enabled ? 1 : 0
  vms-enabled    = var.user-vms-enabled ? 1 : 0
  hasWorker      = var.node_count_worker > 0 ? 1 : 0
}

data "rancher2_user" "acend-training-user" {
  username = "acend-lab-user"
}


data "rancher2_role_template" "project-member" {
  name = "Project Member"
}

data "rancher2_role_template" "view-nodes" {
  name = "View Nodes"
}

data "rancher2_role_template" "view-all-projects" {
  name = "View All Projects"
}

data "rancher2_role_template" "cluster-owner" {
  name = "Cluster Owner"
}

data "rancher2_project" "system" {
  name       = "System"
  cluster_id = rancher2_cluster_sync.training.id
}

resource "rancher2_project" "training" {
  name       = "Training"
  cluster_id = rancher2_cluster_sync.training.id
}

resource "rancher2_project" "quotalab" {
  name       = "kubernetes-quotalab"
  cluster_id = rancher2_cluster_sync.training.id

  resource_quota {
    project_limit {
      requests_cpu    = "30000m"
      requests_memory = "30000Mi"
    }
    namespace_default_limit {
      requests_memory = "100Mi"
      requests_cpu    = "100m"
    }
  }
  container_resource_limit {
    limits_cpu      = "100m"
    limits_memory   = "32Mi"
    requests_cpu    = "10m"
    requests_memory = "16Mi"
  }

}
resource "rancher2_cluster_role_template_binding" "training-view-nodes" {

  name             = "training-view-nodes"
  cluster_id       = rancher2_cluster_sync.training.id
  role_template_id = data.rancher2_role_template.view-nodes.id
  user_id          = data.rancher2_user.acend-training-user.id
}

resource "rancher2_cluster_role_template_binding" "training-view-all-projects" {

  name             = "training-view-all-projects"
  cluster_id       = rancher2_cluster_sync.training.id
  role_template_id = data.rancher2_role_template.view-all-projects.id
  user_id          = data.rancher2_user.acend-training-user.id
}

resource "rancher2_cluster_role_template_binding" "cluster-owner" {

  name             = "cluster-owner"
  cluster_id       = rancher2_cluster_sync.training.id
  role_template_id = data.rancher2_role_template.cluster-owner.id

  group_principal_id = var.cluster_owner_group
}

resource "rancher2_project_role_template_binding" "training-project-member" {

  name             = "training-project-member"
  project_id       = rancher2_project.training.id
  role_template_id = data.rancher2_role_template.project-member.id
  user_id          = data.rancher2_user.acend-training-user.id
}

resource "rancher2_project_role_template_binding" "quotalab-project-member" {

  name             = "quotalab-project-member"
  project_id       = rancher2_project.quotalab.id
  role_template_id = data.rancher2_role_template.project-member.id
  user_id          = data.rancher2_user.acend-training-user.id
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

  depends_on = [rancher2_cluster_sync.training, helm_release.csi-cloudscale, module.student-vms]

  rancher_training_project = rancher2_project.training
  rancher_quotalab_project = rancher2_project.quotalab
  student-index            = count.index
  student-name             = "${var.studentname-prefix}${count.index + 1}"
  student-password         = random_password.student-passwords[count.index].result

  domain = var.domain

  user-vm-enabled = var.user-vms-enabled
  student-vms     = var.user-vms-enabled ? [module.student-vms[0]] : null
  rbac-enabled    = var.webshell-rbac-enabled



  count = var.count-students
}

module "student-vms" {
  source = "./modules/student-vms"


  count-students     = var.count-students
  student-passwords  = random_password.student-passwords
  studentname-prefix = var.studentname-prefix

  ssh_keys = var.ssh_keys


  count = local.vms-enabled
}


# Deploy ArgoCD and configure it for the students
module "argocd" {
  source = "./modules/argocd"

  kubeconfig = rancher2_cluster_sync.training.kube_config


  rancher_system_project   = data.rancher2_project.system
  rancher_training_project = rancher2_project.training

  

  domain             = var.domain
  count-students     = var.count-students
  student-passwords  = random_password.student-passwords
  studentname-prefix = var.studentname-prefix


  count = local.argocd_enabled

  depends_on = [
    rancher2_cluster_sync.training,
    module.webshell // student namespaces are created in the webshell module
  ] 
}

# Deploy Gitea and configure it for the students
module "gitea" {
  source = "./modules/gitea"

  kubeconfig = rancher2_cluster_sync.training.kube_config

  rancher_system_project   = data.rancher2_project.system
  rancher_training_project = rancher2_project.training

  depends_on = [rancher2_cluster_sync.training]

  domain             = var.domain
  count-students     = var.count-students
  student-passwords  = random_password.student-passwords
  studentname-prefix = var.studentname-prefix


  count = local.gitea_enabled
}
