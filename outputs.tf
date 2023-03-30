output "admin_kubeconfig" {
  value = module.training-cluster.kubeconfig_raw
  sensitive = true
}

output "webshell-infos" {
  value = module.training-cluster.webshell-links

}

// Argo CD Output
output "argocd-admin-password" {
  value     = module.training-cluster.argocd-admin-password
  sensitive = true
}

output "argocd-admin-username" {
  value     = module.training-cluster.argocd-admin-username
}

output "argocd-url" {
  value     = module.training-cluster.argocd-url
}

// Gitea Output

output "gitea-admin-password" {
  value     = module.training-cluster.gitea-admin-password
  sensitive = true
}

output "gitea-admin-username" {
  value     = module.training-cluster.gitea-admin-username
}

output "gitea-url" {
  value     = module.training-cluster.gitea-url
}

// Student VM Output

output "student-vm-ip-address" {
  value = module.training-cluster.student-vm-ip-address
}