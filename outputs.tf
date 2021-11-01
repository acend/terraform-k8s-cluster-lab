output "vip_address" {
  value = module.training-cluster.vip_address
}

output "webshell-infos" {
  value = module.training-cluster.webshell-links

}


output "argocd-admin-secret" {
  value = module.training-cluster.argocd-admin-secret
  sensitive = true
}