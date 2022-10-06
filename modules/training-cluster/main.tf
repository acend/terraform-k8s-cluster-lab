
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
  vms-enabled    = var.user-vms-enabled ? 1 : 0
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
      volumes[1],
      user_data
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

  lifecycle {
    ignore_changes = [
      # Ignore changes to volumes
      # cloudscale-csi can add volumes
      volumes[1],
      user_data
    ]
  }

}


# Add a Floating IPv4 address to web-worker01
resource "cloudscale_floating_ip" "vip-v4" {
  server        = cloudscale_server.nodes-master[0].id
  ip_version    = 4
  prefix_length = 32

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
  server        = cloudscale_server.nodes-master[0].id
  ip_version    = 6
  prefix_length = 128

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

      kubelet {
        extra_args = {
          "kube-reserved"   = "cpu=200m,memory=1Gi"
          "system-reserved" = "cpu=200m,memory=1Gi"
          "eviction-hard"   = "memory.available<500Mi"
          "max-pods"        = "70"
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

resource "helm_release" "cloudscale-csi" {

  name       = "cloudscale-csi"
  repository = "https://charts.k8s.puzzle.ch"
  chart      = "cloudscale-csi"
  version    = "0.3.2"
  namespace  = "kube-system"

  set {
    name  = "cloudscale.access_token"
    value = var.cloudscale_token
  }

  set {
    name  = "node.tolerations[0].key"
    value = "node-role.kubernetes.io/controlplane"
  }

  set {
    name  = "node.tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "node.tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "node.tolerations[0].value"
    value = "true"
    type  = "string"
  }

  set {
    name  = "controller.tolerations[0].key"
    value = "node-role.kubernetes.io/controlplane"
  }

  set {
    name  = "controller.tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "controller.tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "controller.tolerations[0].value"
    value = "true"
    type  = "string"
  }



}
resource "helm_release" "cloudscale-vip" {

  name       = "cloudscale-vip-v4"
  repository = "https://charts.k8s.puzzle.ch"
  chart      = "cloudscale-vip"
  version    = "0.1.2"
  namespace  = "kube-system"


  set {
    name  = "cloudscale.access_token"
    value = var.cloudscale_token
  }

  set {
    name  = "keepalived.interface"
    value = "ens3"
  }

  set {
    name  = "keepalived.track_interface"
    value = "ens3"
  }

  set {
    name  = "keepalived.vip"
    value = replace(cloudscale_floating_ip.vip-v4.network, "/32", "")
  }

  set {
    name  = "keepalived.master_host"
    value = cloudscale_server.nodes-master[0].name
  }

  set {
    name  = "keepalived.unicast_peers[0]"
    value = cloudscale_server.nodes-master[0].public_ipv4_address
  }

  set {
    name  = "keepalived.unicast_peers[1]"
    value = cloudscale_server.nodes-master[1].public_ipv4_address
  }

  set {
    name  = "keepalived.unicast_peers[2]"
    value = cloudscale_server.nodes-master[2].public_ipv4_address
  }
  set {
    name  = "nodeSelector.node-role\\.kubernetes\\.io/controlplane"
    value = "true"
    type  = "string"
  }

  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
    value = "node-role.kubernetes.io/controlplane"
  }

  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
    value = "In"
  }
  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
    value = "true"
    type  = "string"
  }

  set {
    name  = "tolerations[0].key"
    value = "node-role.kubernetes.io/controlplane"
  }

  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "tolerations[0].value"
    value = "true"
    type  = "string"
  }

}

resource "helm_release" "cloudscale-vip-v6" {

  name       = "cloudscale-vip-v6"
  repository = "https://charts.k8s.puzzle.ch"
  chart      = "cloudscale-vip"
  version    = "0.1.2"
  namespace  = "kube-system"


  set {
    name  = "cloudscale.access_token"
    value = var.cloudscale_token
  }

  set {
    name  = "keepalived.interface"
    value = "ens3"
  }

  set {
    name  = "keepalived.track_interface"
    value = "ens3"
  }

  set {
    name  = "keepalived.vip"
    value = replace(cloudscale_floating_ip.vip-v6.network, "/128", "")
  }

  set {
    name  = "keepalived.master_host"
    value = cloudscale_server.nodes-master[0].name
  }

  set {
    name  = "keepalived.unicast_peers[0]"
    value = cloudscale_server.nodes-master[0].public_ipv6_address
  }

  set {
    name  = "keepalived.unicast_peers[1]"
    value = cloudscale_server.nodes-master[1].public_ipv6_address
  }

  set {
    name  = "keepalived.unicast_peers[2]"
    value = cloudscale_server.nodes-master[2].public_ipv6_address
  }

  set {
    name  = "nodeSelector.node-role\\.kubernetes\\.io/controlplane"
    value = "true"
    type  = "string"
  }

  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
    value = "node-role.kubernetes.io/controlplane"
  }

  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
    value = "In"
  }
  set {
    name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
    value = "true"
    type  = "string"
  }

  set {
    name  = "tolerations[0].key"
    value = "node-role.kubernetes.io/controlplane"
  }

  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "tolerations[0].value"
    value = "true"
    type  = "string"
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
  override_special = ".-_"

  count = var.count-students
}


# Deploy Webshell with a student Namespace to work in 
module "webshell" {
  source = "./modules/webshell"

  depends_on = [rancher2_cluster_sync.training, helm_release.cloudscale-csi, module.student-vms]

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


  rancher_system_project   = data.rancher2_project.system
  rancher_training_project = rancher2_project.training

  depends_on = [rancher2_cluster_sync.training, module.webshell] // student namespaces are created in the webshell module

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
