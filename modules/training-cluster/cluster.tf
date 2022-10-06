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
  volume_size_gb = 100
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