
provider "rancher2" {
  api_url    = var.rancher2_api_url
  access_key = var.rancher2_access_key
  secret_key = var.rancher2_secret_key
}


data "rancher2_node_template" "staging-flex8" {
  name = var.node_template_name
}


data "rancher2_user" "techlab" {
    username = "techlab"
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

data "rancher2_project" "system" {
  name = "System"
  cluster_id = rancher2_cluster.techlab.id
}


data "rancher2_catalog" "puzzle" {
    name = "puzzle"
}

resource "rancher2_cluster" "techlab" {
  name = var.cluster_name
  description = "Kubernetes Cluster for acend GmbH Techlab"
  rke_config {
    network {
      plugin = "canal"
    }
  }
}

resource "rancher2_node_pool" "techlab" {
  cluster_id =  rancher2_cluster.techlab.id
  name =  var.cluster_name
  hostname_prefix =   "${var.cluster_name}-"
  node_template_id = data.rancher2_node_template.staging-flex8.id
  quantity = 3
  control_plane = true
  etcd = true
  worker = true
}

resource "rancher2_cluster_sync" "techlab" {
  cluster_id =  rancher2_cluster.techlab.id
  node_pool_ids = [rancher2_node_pool.techlab.id]
}

resource "rancher2_project" "techlab" {
  name = "techlab"
  cluster_id = rancher2_cluster_sync.techlab.id
}

resource "rancher2_cluster_role_template_binding" "techlab-view-nodes" {

  name = "techlab-view-nodes"
  cluster_id = rancher2_cluster_sync.techlab.id
  role_template_id = data.rancher2_role_template.view-nodes.id
  user_id = data.rancher2_user.techlab.id
}

resource "rancher2_cluster_role_template_binding" "techlab-view-all-projects" {

  name = "techlab-view-all-projects"
  cluster_id = rancher2_cluster_sync.techlab.id
  role_template_id = data.rancher2_role_template.view-all-projects.id
  user_id = data.rancher2_user.techlab.id
}

resource "rancher2_project_role_template_binding" "techlab-project-member" {

  name = "techlab-project-member"
  project_id = rancher2_project.techlab.id
  role_template_id = data.rancher2_role_template.project-member.id
  user_id = data.rancher2_user.techlab.id
}

resource "rancher2_namespace" "cert-manager" {
  name = "cert-manager"
  project_id = data.rancher2_project.system.id
}

resource "rancher2_app" "cloudscale-csi" {

  catalog_name = data.rancher2_catalog.puzzle.name
  name = "cloudscale-csi"
  project_id = data.rancher2_project.system.id
  template_name = "cloudscale-csi"
  template_version = "0.1.10"
  target_namespace = "kube-system"
  answers = {
    "cloudscale.access_token" = var.cloudscale_token
  }
}


resource "local_file" "kube_config" {
    content     = rancher2_cluster.techlab.kube_config
    filename = "${path.module}/output/kube.config"
}

provider "kubernetes" {
  config_path = "${path.module}/output/kube.config"
}

provider "k8s" {
  config_path = "${path.module}/output/kube.config"
}

provider "helm" {
  kubernetes {
    config_path = "${path.module}/output/kube.config"
  }
}

resource "helm_release" "certmanager" {

  depends_on = [rancher2_namespace.cert-manager]


  name  = "certmanager"
  repository = "https://charts.jetstack.io" 
  chart = "cert-manager"
  version    = "v0.15.0"
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
  template = "${file("${path.module}/manifests/letsencrypt-prod.yaml")}"

  vars = {
    letsencrypt_email = var.letsencrypt_email
  }
}


resource "k8s_manifest" "clusterissuer-letsencrypt-prod" {
  content = data.template_file.clusterissuer-letsencrypt-prod.rendered
}