
provider "rancher2" {
  api_url    = var.rancher2_api_url
  access_key = var.rancher2_access_key
  secret_key = var.rancher2_secret_key
}


locals {
  kube_config = yamldecode(rancher2_cluster_sync.training.kube_config)
  kube_host = local.kube_config.clusters[0].cluster.server
  kube_token = local.kube_config.users[0].user.token

}


data "rancher2_node_template" "node_template" {
  name = var.node_template_name
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
  name = "System"
  cluster_id = rancher2_cluster_sync.training.id
}


data "rancher2_catalog" "puzzle" {
    name = "puzzle"
}

resource "rancher2_cluster" "training" {
  name = var.cluster_name
  description = "Kubernetes Cluster for acend GmbH Training"
  rke_config {
    network {
      plugin = "canal"
    }
  }
}

resource "rancher2_node_pool" "training" {
  cluster_id =  rancher2_cluster.training.id
  name =  var.cluster_name
  hostname_prefix =   "${var.cluster_name}-"
  node_template_id = data.rancher2_node_template.node_template.id
  quantity = 3
  control_plane = true
  etcd = true
  worker = true
}

resource "rancher2_cluster_sync" "training" {
  cluster_id =  rancher2_cluster.training.id
  node_pool_ids = [rancher2_node_pool.training.id]
}

resource "rancher2_project" "training" {
  name = "Training"
  cluster_id = rancher2_cluster_sync.training.id
}


resource "rancher2_cluster_role_template_binding" "training-view-nodes" {

  name = "training-view-nodes"
  cluster_id = rancher2_cluster_sync.training.id
  role_template_id = data.rancher2_role_template.view-nodes.id
  user_id = data.rancher2_user.acend-training-user.id
}

resource "rancher2_cluster_role_template_binding" "training-view-all-projects" {

  name = "training-view-all-projects"
  cluster_id = rancher2_cluster_sync.training.id
  role_template_id = data.rancher2_role_template.view-all-projects.id
  user_id = data.rancher2_user.acend-training-user.id
}

resource "rancher2_cluster_role_template_binding" "cluster-owner" {

  name = "cluster-owner"
  cluster_id = rancher2_cluster_sync.training.id
  role_template_id = data.rancher2_role_template.cluster-owner.id

  group_principal_id = var.cluster_owner_group
}

resource "rancher2_project_role_template_binding" "training-project-member" {

  name = "training-project-member"
  project_id = rancher2_project.training.id
  role_template_id = data.rancher2_role_template.project-member.id
  user_id = data.rancher2_user.acend-training-user.id
}


resource "rancher2_namespace" "cert-manager" {

  name = "cert-manager"
  project_id = data.rancher2_project.system.id
}

resource "rancher2_app" "cloudscale-csi" {

  depends_on = [rancher2_cluster_sync.training]

  catalog_name = data.rancher2_catalog.puzzle.name
  name = "cloudscale-csi"
  project_id = data.rancher2_project.system.id
  template_name = "cloudscale-csi"
  template_version = "0.1.13"
  target_namespace = "kube-system"
  answers = {
    "cloudscale.access_token" = var.cloudscale_token
  }
}

provider "k8s" {
  #config_path = "${path.module}/output/kube.config"
  host             = local.kube_host
  token            = local.kube_token
  load_config_file = "false"
}


provider "helm" {
  kubernetes {
    #config_path = "${path.module}/output/kube.config"
    host = local.kube_host
    token = local.kube_token
  }
}

resource "helm_release" "certmanager" {

  depends_on = [rancher2_namespace.cert-manager]


  name  = "certmanager"
  repository = "https://charts.jetstack.io" 
  chart = "cert-manager"
  version    = "v1.1.0"
  namespace = "cert-manager"

  set {
    name  = "installCRDs"
    value = true
  }

  set {
    name = "ingressShim.defaultIssuerName"
    value = "letsencrypt-prod"
  }

  set {
    name = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }

}

data "template_file" "clusterissuer-letsencrypt-prod" {
  template = file("${path.module}/manifests/letsencrypt-prod.yaml")

  vars = {
    letsencrypt_email = var.letsencrypt_email
  }
}

resource "k8s_manifest" "clusterissuer-letsencrypt-prod" {
  depends_on = [rancher2_cluster_sync.training, helm_release.certmanager]
  content = data.template_file.clusterissuer-letsencrypt-prod.rendered
}