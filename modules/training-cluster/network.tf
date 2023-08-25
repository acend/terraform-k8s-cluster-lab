resource "hcloud_network" "network" {
  name     = var.cluster_name
  ip_range = var.network

  labels = {
    cluster : var.cluster_name,
  }
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = var.networkzone
  ip_range     = var.subnetwork
}

resource "hcloud_load_balancer" "lb" {
  name               = "lb-k8s-${var.cluster_name}"
  load_balancer_type = var.lb_type
  location           = var.location

  labels = {
    cluster : var.cluster_name,
  }
}

resource "hcloud_load_balancer_network" "lb" {
  load_balancer_id = hcloud_load_balancer.lb.id
  network_id       = hcloud_network.network.id
  ip               = var.internalbalancerip
}

resource "hcloud_load_balancer_service" "rke2" {
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "tcp"
  listen_port      = 9345
  destination_port = 9345
  health_check {
    protocol = "tcp"
    port     = 9345
    interval = 5
    timeout  = 2
    retries  = 5
  }
}

resource "hcloud_load_balancer_service" "api" {
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 5
    timeout  = 2
    retries  = 2
  }
}

resource "hcloud_load_balancer_target" "controlplane" {
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.lb.id
  label_selector   = "cluster=${var.cluster_name},controlplane=true"
  use_private_ip   = true
  depends_on = [
    hcloud_load_balancer_network.lb,
    hcloud_network_subnet.subnet
  ]
}

resource "hcloud_firewall" "firewall" {
  name = "k8s-cluster-${var.cluster_name}"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "9345"
    source_ips = [for server in hcloud_server.controlplane : "${server.ipv4_address}/32"]
  }

  // Allow Nde Ports from everywhere
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "30000-32767"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  apply_to {
    label_selector = "cluster=${var.cluster_name}"
  }
}
