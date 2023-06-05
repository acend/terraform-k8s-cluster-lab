

resource "tls_private_key" "user-ssh-key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"

  count = var.count-students
}

data "template_file" "cloudinit_uservm" {
  template = file("${path.module}/manifests/cloudinit.yaml")

  vars = {
    username = "${var.studentname-prefix}${count.index + 1}"
    sshkey   = tls_private_key.user-ssh-key[count.index].public_key_openssh
  }

  count = var.count-students
}

resource "hcloud_server" "user-vm" {
  count = var.count-students

  lifecycle {
    ignore_changes = [
      # Ignore user_data for existing nodes as this requires a replacement
      user_data
    ]
  }

  name        = "vm-${var.studentname-prefix}-${count.index + 1}"
  location    = var.location
  image       = "ubuntu-22.04"
  server_type = "cpx31"

  labels = {
    cluster : var.cluster_name,
    uservm : "true"
  }

  ssh_keys = [var.var.ssh_key]

  user_data = data.template_file.cloudinit_uservm[count.index].rendered
}

