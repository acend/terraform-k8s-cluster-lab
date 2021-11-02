output "vip_address" {
  value = replace(cloudscale_floating_ip.vip-v4.network, "/32", "")
}

output "vip_address_v6" {
  value = replace(cloudscale_floating_ip.vip-v6.network, "/128", "")
}


output "webshell-links" {
  value = module.webshell.*.student-direct-webshelllink
}
output "argocd-admin-secret" {
  value = module.argocd[0].admin-secret
}