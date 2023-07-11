output "admin_kubeconfig" {
  value     = module.training-cluster.kubeconfig_raw
  sensitive = true
}

// Argo CD Output
output "argocd-admin-password" {
  value     = module.training-cluster.argocd-admin-password
  sensitive = true
}

output "argocd-admin-username" {
  value = module.training-cluster.argocd-admin-username
}

output "argocd-url" {
  value = module.training-cluster.argocd-url
}
