output "kubeconfig_raw" {
  value = local.kubeconfig_raw
}

output "argocd-admin-username" {
  value = "admin"
}

output "argocd-admin-password" {
  value = data.kubernetes_secret.argocd-admin-secret.data.password
}

output "argocd-url" {
  value = "https://argocd.${var.cluster_name}.${var.cluster_domain}"
}

output "gitea-admin-password" {
  value = module.gitea.admin-password
}

output "gitea-admin-username" {
  value = module.gitea.admin-username
}

output "gitea-url" {
  value = module.gitea.gitea-url
}