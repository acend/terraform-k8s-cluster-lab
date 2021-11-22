// Cluster Output

output "vip_address" {
  value = module.training-cluster.vip_address
}

output "vip_address_v6" {
  value = module.training-cluster.vip_address_v6
}

// Webshell & Student Output

output "webshell-infos" {
  value = module.training-cluster.webshell-links

}

// Argo CD Output

output "argocd-admin-secret" {
  value     = module.training-cluster.argocd-admin-secret
  sensitive = true
}
