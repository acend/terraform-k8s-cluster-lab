

resource "tls_private_key" "user-ssh-key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"

  count = var.count-students
}

data "template_file" "cloudinit_uservm" {
  template = file("${path.module}/manifests/cloudinit.yaml")

  vars = {
    username = "${var.studentname-prefix}${count.index}"
    sshkey = tls_private_key.user-ssh-key[count.index].public_key_openssh
  }

  count = var.count-students
}

resource "cloudscale_server" "user-vm" {
  name           = "vm-${var.studentname-prefix}-${count.index}"
  flavor_slug    = var.vm-flavor
  image_slug     = "ubuntu-20.04"
  volume_size_gb = 50
  ssh_keys       = concat(var.ssh_keys, [tls_private_key.user-ssh-key[count.index].public_key_openssh])
  use_ipv6       = true

  user_data = data.template_file.cloudinit_uservm[count.index].rendered


  lifecycle {
    ignore_changes = [
      # Ignore changes to volumes
      # cloudscale-csi can add volumes

      user_data
    ]
  }

  count = var.count-students

}