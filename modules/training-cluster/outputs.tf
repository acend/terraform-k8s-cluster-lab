output "kubeconfig_raw" {
  value = local.kubeconfig_raw
}

output "argocd-admin-username" {
  value = "admin"
}

output "argocd-admin-password" {
  value = random_password.argocd-admin-password.result
}

output "argocd-url" {
  value = "https://argocd.${var.cluster_name}.${var.cluster_domain}"
}

output "gitea-admin-password" {
  value = random_password.gitea-admin-password.result
}

output "gitea-admin-username" {
  value = "gitea_admin"
}

output "gitea-url" {
  value = "https://gitea.${var.cluster_name}.${var.cluster_domain}"
}