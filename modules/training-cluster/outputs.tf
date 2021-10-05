output "vip_address" {
  value = replace(cloudscale_floating_ip.vip-v4.network, "/32", "")
}

output "webshell-links" {
  value = "${join("\n", module.webshell.*.student-direct-webshelllink)}"
}