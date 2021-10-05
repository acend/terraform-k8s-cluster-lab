output "vip_address" {
  value = module.training-cluster.vip_address
}

output "webshell-infos" {
  value     = nonsensitive(module.training-cluster.webshell-links)

}