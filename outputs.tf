// Cluster Output

output "vip_address" {
  value = module.training-cluster.vip_address
}


// Webshell Output

output "webshell-infos" {
  value = module.training-cluster.webshell-links

}

// Argo CD Output

output "argocd-admin-secret" {
  value = module.training-cluster.argocd-admin-secret
  sensitive = true
}

output "argocd-student-password" {
  value = module.training-cluster.argocd-student-password
}