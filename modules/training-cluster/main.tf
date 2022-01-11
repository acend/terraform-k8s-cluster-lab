
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
  cilium_enabled = var.network_plugin == "cilium" ? 1 : 0
  argocd_enabled = var.argocd-enabled ? 1 : 0
  gitea_enabled  = var.gitea-enabled ? 1 : 0
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

data "rancher2_catalog" "puzzle" {
  name = "puzzle"
}

data "template_file" "cloudinit_master" {
  template = file("${path.module}/manifests/cloudinit.yaml")

  vars = {
    cluster_join_command = "${rancher2_cluster.training.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
  }
}

data "template_file" "cloudinit_worker" {
  template = file("${path.module}/manifests/cloudinit.yaml")

  vars = {
    cluster_join_command = "${rancher2_cluster.training.cluster_registration_token[0].node_command} --worker"
  }
}

resource "cloudscale_server" "nodes-master" {
  name           = "${var.cluster_name}-node-master-${count.index}"
  flavor_slug    = var.node_flavor_master
  image_slug     = "ubuntu-20.04"
  volume_size_gb = 50
  ssh_keys       = var.ssh_keys
  use_ipv6       = true

  user_data = data.template_file.cloudinit_master.rendered

  lifecycle {
    ignore_changes = [
      # Ignore changes to volumes
      # cloudscale-csi can add volumes
      volumes[1]
    ]
  }

  count = var.node_count_master

}

resource "cloudscale_server" "nodes-worker" {
  name           = "${var.cluster_name}-node-worker-${count.index}"
  flavor_slug    = var.node_flavor_worker
  image_slug     = "ubuntu-20.04"
  volume_size_gb = 50
  ssh_keys       = var.ssh_keys
  use_ipv6       = true

  user_data = data.template_file.cloudinit_worker.rendered

  count = var.node_count_worker

}


# Add a Floating IPv4 address to web-worker01
resource "cloudscale_floating_ip" "vip-v4" {
  server     = cloudscale_server.nodes-master[0].id
  ip_version = 4

  lifecycle {
    ignore_changes = [
      # Ignore changes to server
      # keepalived can reasign
      server
    ]
  }
}

# Add a Floating IPv6 network to web-worker01
resource "cloudscale_floating_ip" "vip-v6" {
  server     = cloudscale_server.nodes-master[0].id
  ip_version = 6

  lifecycle {
    ignore_changes = [
      # Ignore changes to server
      # keepalived can reasign
      server
    ]
  }
}


resource "rancher2_cluster" "training" {
  name        = var.cluster_name
  description = "Kubernetes Cluster for acend GmbH Training"

  rke_config {

    kubernetes_version = var.kubernetes_version
    network {
      plugin = lookup(var.rke_network_plugin, var.network_plugin, "canal")
    }
    services {
      kube_api {
        extra_args = {
          feature-gates = "RemoveSelfLink=false"
        }
      }
    }
  }
}
resource "rancher2_cluster_sync" "training" {

  depends_on = [cloudscale_server.nodes-master]


  cluster_id    = rancher2_cluster.training.id
  state_confirm = 3

  timeouts {
    create = "30m"
  }
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

resource "rancher2_app" "cloudscale-csi" {

  catalog_name     = data.rancher2_catalog.puzzle.name
  name             = "cloudscale-csi"
  project_id       = data.rancher2_project.system.id
  template_name    = "cloudscale-csi"
  template_version = "0.2.3"
  target_namespace = "kube-system"
  answers = {
    "cloudscale.access_token" = var.cloudscale_token
  }
}

resource "rancher2_app" "cloudscale-vip" {

  catalog_name     = data.rancher2_catalog.puzzle.name
  name             = "cloudscale-vip-v4"
  project_id       = data.rancher2_project.system.id
  template_name    = "cloudscale-vip"
  template_version = "0.1.2"
  target_namespace = "kube-system"
  answers = {
    "cloudscale.access_token"     = var.cloudscale_token
    "keepalived.interface"        = "ens3"
    "keepalived.track_interface"  = "ens3"
    "keepalived.vip"              = replace(cloudscale_floating_ip.vip-v4.network, "/32", "")
    "keepalived.master_host"      = cloudscale_server.nodes-master[0].name
    "keepalived.unicast_peers[0]" = cloudscale_server.nodes-master[0].public_ipv4_address
    "keepalived.unicast_peers[1]" = cloudscale_server.nodes-master[1].public_ipv4_address
    "keepalived.unicast_peers[2]" = cloudscale_server.nodes-master[2].public_ipv4_address
    "nodeSelector.vip"            = "true"
  }
}

resource "rancher2_app" "cloudscale-vip-v6" {

  catalog_name     = data.rancher2_catalog.puzzle.name
  name             = "cloudscale-vip-v6"
  project_id       = data.rancher2_project.system.id
  template_name    = "cloudscale-vip"
  template_version = "0.1.2"
  target_namespace = "kube-system"
  answers = {
    "cloudscale.access_token"     = var.cloudscale_token
    "keepalived.interface"        = "ens3"
    "keepalived.track_interface"  = "ens3"
    "keepalived.vip"              = replace(cloudscale_floating_ip.vip-v6.network, "/128", "")
    "keepalived.master_host"      = cloudscale_server.nodes-master[0].name
    "keepalived.unicast_peers[0]" = cloudscale_server.nodes-master[0].public_ipv6_address
    "keepalived.unicast_peers[1]" = cloudscale_server.nodes-master[1].public_ipv6_address
    "keepalived.unicast_peers[2]" = cloudscale_server.nodes-master[2].public_ipv6_address
    "nodeSelector.vip"            = "true"
  }
}


# Deploy Cert-Manager for Certificates
module "cert-manager" {
  source = "./modules/cert-manager"

  depends_on = [rancher2_cluster_sync.training]

  letsencrypt_email      = var.letsencrypt_email
  rancher_system_project = data.rancher2_project.system

  acme-config = var.acme-config
}

# Deploy Cilium CNI if enabled
module "cilium" {
  source = "./modules/cilium"

  depends_on = [rancher2_cluster_sync.training]

  rancher_system_project = data.rancher2_project.system
  public_ip              = replace(cloudscale_floating_ip.vip-v4.network, "/32", "")

  count = local.cilium_enabled
}


# Create Passwords for the students (shared by multiple apps like webshell, argocd and gitea)
resource "random_password" "student-passwords" {
  length           = 16
  special          = true
  override_special = "_%@"

  count = var.count-students
}


# Deploy Webshell with a student Namespace to work in 
module "webshell" {
  source = "./modules/webshell"

  depends_on = [rancher2_cluster_sync.training, rancher2_app.cloudscale-csi]

  rancher_training_project = rancher2_project.training
  rancher_quotalab_project = rancher2_project.quotalab
  student-name             = "${var.studentname-prefix}${count.index + 1}"
  student-password         = random_password.student-passwords[count.index].result

  count = var.count-students
}

# Deploy ArgoCD and configure it for the students
module "argocd" {
  source = "./modules/argocd"

  rancher_system_project   = data.rancher2_project.system
  rancher_training_project = rancher2_project.training

  depends_on = [rancher2_cluster_sync.training]

  count-students     = var.count-students
  student-passwords  = random_password.student-passwords
  studentname-prefix = var.studentname-prefix


  count = local.argocd_enabled
}

# Deploy Gitea and configure it for the students
module "gitea" {
  source = "./modules/gitea"

  rancher_system_project   = data.rancher2_project.system
  rancher_training_project = rancher2_project.training

  depends_on = [rancher2_cluster_sync.training]

  count-students     = var.count-students
  student-passwords  = random_password.student-passwords
  studentname-prefix = var.studentname-prefix


  count = local.gitea_enabled
}
