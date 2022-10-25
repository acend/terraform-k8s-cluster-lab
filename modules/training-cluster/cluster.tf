resource "cloudscale_server" "nodes-master" {
  name           = "${var.cluster_name}-node-master-${count.index}"
  flavor_slug    = var.node_flavor_master
  image_slug     = "ubuntu-20.04"
  volume_size_gb = 100
  ssh_keys       = var.ssh_keys
  use_ipv6       = true

  user_data = "${templatefile(
    "${path.module}/manifests/cloudinit.yaml",
    {
      cluster_join_command = "${rancher2_cluster_v2.training.cluster_registration_token[0].node_command} --etcd --controlplane --worker"
    }
    )}"

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

  user_data = "${templatefile(
    "${path.module}/manifests/cloudinit.yaml",
    {
      cluster_join_command = "${rancher2_cluster_v2.training.cluster_registration_token[0].node_command} --worker"
    }
    )}"

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

resource "null_resource" "cleanup-node-before-destroy" {

  triggers = {
    kubeconfig = base64encode(rancher2_cluster_sync.training.kube_config)
    node_name = cloudscale_server.nodes-worker[count.index].name
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<EOH
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
chmod +x ./kubectl

./kubectl drain node $NODE_NAME --kubeconfig <(echo $KUBECONFIG | base64 --decode) || true
./kubectl delete node $NODE_NAME --kubeconfig <(echo $KUBECONFIG | base64 --decode) || true
EOH
    interpreter = ["/bin/bash", "-c"]
environment = {
      KUBECONFIG = self.triggers.kubeconfig
      NODE_NAME = self.triggers.node_name
  }
 }

 depends_on = [
   cloudscale_server.nodes-worker
 ]

 count = var.node_count_worker
}

resource "null_resource" "taint-master-when-worker-available" {

  triggers = {
    kubeconfig = base64encode(rancher2_cluster_sync.training.kube_config)
    clusterName = var.cluster_name
  }

  provisioner "local-exec" {
    command = <<EOH
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
chmod +x ./kubectl

./kubectl taint node $CLUSTERNAME-node-master-0 node-role.kubernetes.io/control-plane:NoSchedule --kubeconfig <(echo $KUBECONFIG | base64 --decode)
./kubectl taint node $CLUSTERNAME-node-master-1 node-role.kubernetes.io/control-plane:NoSchedule --kubeconfig <(echo $KUBECONFIG | base64 --decode)
./kubectl taint node $CLUSTERNAME-node-master-2 node-role.kubernetes.io/control-plane:NoSchedule --kubeconfig <(echo $KUBECONFIG | base64 --decode)

EOH
    interpreter = ["/bin/bash", "-c"]
environment = {
      KUBECONFIG = self.triggers.kubeconfig
      CLUSTERNAME = self.triggers.clusterName
  }
 }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOH
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
chmod +x ./kubectl

./kubectl taint node $CLUSTERNAME-node-master-0 node-role.kubernetes.io/control-plane- --kubeconfig <(echo $KUBECONFIG | base64 --decode)
./kubectl taint node $CLUSTERNAME-node-master-1 node-role.kubernetes.io/control-plane- --kubeconfig <(echo $KUBECONFIG | base64 --decode)
./kubectl taint node $CLUSTERNAME-node-master-2 node-role.kubernetes.io/control-plane- --kubeconfig <(echo $KUBECONFIG | base64 --decode)
EOH
    interpreter = ["/bin/bash", "-c"]
environment = {
      KUBECONFIG = self.triggers.kubeconfig
      CLUSTERNAME = self.triggers.clusterName
  }
 }

 count = local.hasWorker

 depends_on = [
   cloudscale_server.nodes-worker
 ]
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

resource "rancher2_cluster_v2" "training" {
  name               = "${var.cluster_name}-rke2"
  kubernetes_version = var.kubernetes_version

  rke_config {

    machine_global_config = <<EOF
cni: "cilium"

EOF

    chart_values = <<EOF
  rke2-cilium:
    {}
EOF
  }

}
resource "rancher2_cluster_sync" "training" {

  depends_on = [cloudscale_server.nodes-master]


  cluster_id    = rancher2_cluster_v2.training.cluster_v1_id
  state_confirm = 3

  timeouts {
    create = "30m"
  }
}

resource "kubernetes_secret" "cloudscale" {
  metadata {
    name      = "cloudscale"
    namespace = "kube-system"
  }

  data = {
    access-token = var.cloudscale_token
  }

  type = "Opaque"
}

resource "helm_release" "csi-cloudscale" {

  name       = "csi-cloudscale"
  repository = "https://cloudscale-ch.github.io/csi-cloudscale"
  chart      = "csi-cloudscale"
  version    = "1.1.1"
  namespace  = "kube-system"

  set {
    name  = "cloudscale.token.existingSecret"
    value = kubernetes_secret.cloudscale.metadata[0].name
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