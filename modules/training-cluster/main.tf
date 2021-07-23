
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


provider "helm" {
  kubernetes {
    #config_path = "${path.module}/output/kube.config"
    host = local.kube_host
    token = local.kube_token
  }
}


locals {
  kube_config = yamldecode(rancher2_cluster_sync.training.kube_config)
  kube_host = local.kube_config.clusters[0].cluster.server
  kube_token = local.kube_config.users[0].user.token
  cilium_enabled = var.network_plugin == "cilium" ? 1 : 0
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

data "template_file" "cloudinit" {
  template = file("${path.module}/manifests/cloudinit.yaml")
}

resource "cloudscale_server" "node01" {
  name                = "${var.cluster_name}-node01"
  flavor_slug         = "flex-8"
  image_slug          = "ubuntu-20.04"
  volume_size_gb      = 50
  ssh_keys            = var.ssh_keys
  use_ipv6            = true

  user_data = data.template_file.cloudinit.rendered

  provisioner "remote-exec" {
    inline = [
      "${rancher2_cluster.training.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
    ]
    on_failure = continue

    connection {
      type     = "ssh"
      user     = "ubuntu"
      host     = self.public_ipv4_address
    }
  }
}

  resource "cloudscale_server" "node02" {
  name                = "${var.cluster_name}-node02"
  flavor_slug         = "flex-8"
  image_slug          = "ubuntu-20.04"
  volume_size_gb      = 50
  ssh_keys            = var.ssh_keys
  use_ipv6            = true

  user_data = data.template_file.cloudinit.rendered

  provisioner "remote-exec" {
    inline = [
      "${rancher2_cluster.training.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
    ]
    on_failure = continue

    connection {
      type     = "ssh"
      user     = "ubuntu"
      host     = self.public_ipv4_address
    }
  }

}

  resource "cloudscale_server" "node03" {
  name                = "${var.cluster_name}-node03"
  flavor_slug         = "flex-8"
  image_slug          = "ubuntu-20.04"
  volume_size_gb      = 50
  ssh_keys            = var.ssh_keys
  use_ipv6            = true

  user_data = data.template_file.cloudinit.rendered

  provisioner "remote-exec" {
    inline = [
      "${rancher2_cluster.training.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
    ]
    on_failure = continue

    connection {
      type     = "ssh"
      user     = "ubuntu"
      host     = self.public_ipv4_address
    }
  }

}

# Add a Floating IPv4 address to web-worker01
resource "cloudscale_floating_ip" "vip-v4" {
  server      = cloudscale_server.node01.id
  ip_version  = 4

  lifecycle {
    ignore_changes = [
      # Ignore changes to server
      # keepalived can reasign
      server
    ]
  }
}

# # Add a Floating IPv6 network to web-worker01
# resource "cloudscale_floating_ip" "vip-v6" {
#   server        = cloudscale_server.node01.id
#   ip_version    = 6
#   prefix_length = 56

#   lifecycle {
#     ignore_changes = [
#       # Ignore changes to server
#       # keepalived can reasign
#       server
#     ]
#   }
# }


resource "rancher2_cluster" "training" {
  name = var.cluster_name
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
  cluster_id =  rancher2_cluster.training.id
  state_confirm = 3
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


resource "rancher2_app" "cloudscale-csi" {

  depends_on = [rancher2_cluster_sync.training]

  catalog_name = data.rancher2_catalog.puzzle.name
  name = "cloudscale-csi"
  project_id = data.rancher2_project.system.id
  template_name = "cloudscale-csi"
  template_version = "0.2.0"
  target_namespace = "kube-system"
  answers = {
    "cloudscale.access_token" = var.cloudscale_token
  }
}

resource "rancher2_app" "cloudscale-vip" {

  depends_on = [rancher2_cluster_sync.training]

  catalog_name = data.rancher2_catalog.puzzle.name
  name = "cloudscale-vip-v4"
  project_id = data.rancher2_project.system.id
  template_name = "cloudscale-vip"
  template_version = "0.1.0"
  target_namespace = "kube-system"
  answers = {
    "cloudscale.access_token" = var.cloudscale_token
    "keepalived.interface" = "ens3"
    "keepalived.track_interface" = "ens3"
    "keepalived.vip" = replace(cloudscale_floating_ip.vip-v4.network, "/32", "" )
    "keepalived.master_host" = cloudscale_server.node01.name
    "keepalived.unicast_peers[0]" = cloudscale_server.node01.public_ipv4_address
    "keepalived.unicast_peers[1]" = cloudscale_server.node02.public_ipv4_address
    "keepalived.unicast_peers[2]" = cloudscale_server.node03.public_ipv4_address
  }
}

module "training-cluster" {
  source = "./modules/cert-manager"

  letsencrypt_email = var.letsencrypt_email
  project_id = data.rancher2_project.system.id


}

module "cilium" {
  source = "./modules/cilium"

  project_id = data.rancher2_project.system.id
  public_ip = replace(cloudscale_floating_ip.vip-v4.network, "/32", "" )

  count = local.cilium_enabled

}

