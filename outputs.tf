// Cluster Output

output "vip_address" {
  value = module.training-cluster.vip_address
}


// Webshell & Student Output

output "webshell-infos" {
  value = module.training-cluster.webshell-links

}

// Argo CD Output

output "argocd-admin-secret" {
  value = module.training-cluster.argocd-admin-secret
  sensitive = true
}
