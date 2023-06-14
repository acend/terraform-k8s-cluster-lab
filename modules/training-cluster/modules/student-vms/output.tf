output "user-ssh-keys" {
  value = tls_private_key.user-ssh-key.*
}


output "ip-address" {
  value = hcloud_server.user-vm.*.ipv4_address
}

output "ipv6-address" {
  value = hcloud_server.user-vm.*.ipv6_address
}