output "user-ssh-keys" {
  value = tls_private_key.user-ssh-key.*
}


output "ip-address" {
  value = cloudscale_server.user-vm.*.public_ipv4_address
}