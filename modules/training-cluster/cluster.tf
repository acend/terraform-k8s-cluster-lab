resource "tls_private_key" "terraform" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "hcloud_ssh_key" "terraform" {
  name       = "terraform-${var.cluster_name}"
  public_key = tls_private_key.terraform.public_key_openssh
}

// Control Plane Node
resource "hcloud_placement_group" "controlplane" {
  name = "controlplane-${var.cluster_name}"
  type = "spread"
  labels = {
    cluster : var.cluster_name,
    controlplane : "true"
  }
}

resource "hcloud_server" "controlplane" {

  depends_on = [
    hcloud_load_balancer_service.rke2,
    hcloud_load_balancer_target.controlplane
  ]

  count = var.controlplane_count

  lifecycle {
    ignore_changes = [
      # Ignore user_data for existing nodes as this requires a replacement
      user_data
    ]
  }

  name        = "${var.cluster_name}-controlplane-${count.index}"
  location    = var.location
  image       = var.node_image_type
  server_type = var.controlplane_type

  placement_group_id = hcloud_placement_group.controlplane.id

  labels = {
    cluster : var.cluster_name,
    controlplane : "true"
  }

  ssh_keys = [hcloud_ssh_key.terraform.name]


  user_data = templatefile("${path.module}/manifests/cloudinit-controlplane.yaml", {
    api_token = var.hcloud_api_token,

    clustername = var.cluster_name,

    rke2_version        = var.rke2_version,
    rke2_cluster_secret = random_password.rke2_cluster_secret.result

    extra_ssh_keys = var.extra_ssh_keys,

    lb_id          = hcloud_load_balancer.lb.id,
    lb_address     = hcloud_load_balancer_network.lb.ip,
    lb_external_v4 = hcloud_load_balancer.lb.ipv4,
    lb_external_v6 = hcloud_load_balancer.lb.ipv6,

    network = hcloud_network.network.id

    controlplane_index = count.index,

    k8s_api_hostnames = ["api.${var.cluster_name}.${var.cluster_domain}"]

    k8s-cluster-cidr = var.k8s-cluster-cidr
    networkzone      = var.networkzone
    location         = var.location

    first_install = var.first_install
  })
}

resource "hcloud_server_network" "controlplane" {
  count      = var.controlplane_count
  server_id  = hcloud_server.controlplane[count.index].id
  network_id = hcloud_network.network.id
}

// Worker Node
resource "hcloud_server" "worker" {
  count = var.worker_count

  lifecycle {
    ignore_changes = [
      # Ignore user_data for existing nodes as this requires a replacement
      user_data
    ]
  }


  name        = "${var.cluster_name}-worker-${count.index}"
  location    = var.location
  image       = var.node_image_type
  server_type = var.worker_type

  labels = {
    cluster : var.cluster_name,
    worker : "true"
  }

  ssh_keys = [hcloud_ssh_key.terraform.name]

  user_data = templatefile("${path.module}/manifests/cloudinit-worker.yaml", {
    api_token = var.hcloud_api_token,

    clustername = var.cluster_name,

    rke2_version        = var.rke2_version,
    rke2_cluster_secret = random_password.rke2_cluster_secret.result,

    extra_ssh_keys = var.extra_ssh_keys,

    lb_address = hcloud_load_balancer_network.lb.ip,
    lb_id      = hcloud_load_balancer.lb.id,

    worker_index = count.index
  })
}

resource "hcloud_server_network" "worker" {
  count      = var.worker_count
  server_id  = hcloud_server.worker[count.index].id
  network_id = hcloud_network.network.id
}
