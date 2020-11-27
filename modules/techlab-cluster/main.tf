
provider "rancher2" {
  api_url    = var.rancher2_api_url
  access_key = var.rancher2_access_key
  secret_key = var.rancher2_secret_key
}


data "rancher2_node_template" "node_template" {
  name = var.node_template_name
}


data "rancher2_user" "acend-lab-user" {
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

data "rancher2_project" "system" {
  name = "System"
  cluster_id = rancher2_cluster_sync.lab.id
}


data "rancher2_catalog" "puzzle" {
    name = "puzzle"
}

resource "rancher2_cluster" "lab" {
  name = var.cluster_name
  description = "Kubernetes Cluster for acend GmbH Lab"
  rke_config {
    network {
      plugin = "canal"
    }
  }
}

resource "rancher2_node_pool" "lab" {
  cluster_id =  rancher2_cluster.lab.id
  name =  var.cluster_name
  hostname_prefix =   "${var.cluster_name}-"
  node_template_id = data.rancher2_node_template.node_template.id
  quantity = 3
  control_plane = true
  etcd = true
  worker = true
}

resource "rancher2_cluster_sync" "lab" {
  cluster_id =  rancher2_cluster.lab.id
  node_pool_ids = [rancher2_node_pool.lab.id]
}

resource "rancher2_project" "lab" {
  name = "lab"
  cluster_id = rancher2_cluster_sync.lab.id
}


resource "rancher2_cluster_role_template_binding" "telabchlab-view-nodes" {

  name = "lab-view-nodes"
  cluster_id = rancher2_cluster_sync.lab.id
  role_template_id = data.rancher2_role_template.view-nodes.id
  user_id = data.rancher2_user.acend-lab-user.id
}

resource "rancher2_cluster_role_template_binding" "lab-view-all-projects" {

  name = "lab-view-all-projects"
  cluster_id = rancher2_cluster_sync.lab.id
  role_template_id = data.rancher2_role_template.view-all-projects.id
  user_id = data.rancher2_user.acend-lab-user.id
}

resource "rancher2_project_role_template_binding" "lab-project-member" {

  name = "lab-project-member"
  project_id = rancher2_project.lab.id
  role_template_id = data.rancher2_role_template.project-member.id
  user_id = data.rancher2_user.acend-lab-user.id
}

resource "rancher2_namespace" "cert-manager" {

  name = "cert-manager"
  project_id = data.rancher2_project.system.id
}

resource "rancher2_app" "cloudscale-csi" {

  depends_on = [rancher2_cluster_sync.lab]

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


resource "local_file" "kube_config" {
    content     = rancher2_cluster.lab.kube_config
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
  version    = "v1.0.3"
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

  depends_on = [rancher2_cluster_sync.lab]
  
  content = data.template_file.clusterissuer-letsencrypt-prod.rendered
}