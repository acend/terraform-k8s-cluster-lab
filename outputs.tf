output "admin_kubeconfig" {
  value = module.training-cluster.kubeconfig_raw
  sensitive = true
}

output "webshell-infos" {
  value = module.training-cluster.webshell-links

}

// Argo CD Output
output "argocd-admin-secret" {
  value     = module.training-cluster.argocd-admin-secret
  sensitive = true
}

// Gitea Output

output "gitea-admin-password" {
  value     = module.training-cluster.gitea-admin-password
  sensitive = true
}

// Student VM Output

output "student-vm-ip-address" {
  value = module.training-cluster.student-vm-ip-address
}