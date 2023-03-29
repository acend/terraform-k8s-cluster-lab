output "admin-username" {
  value = "admin"
}

output "admin-password" {
  value = data.kubernetes_secret.admin-secret.data.password
}


output "argocd-url" {
  value = "https://argocd.${var.cluster_name}.${var.cluster_domain}"
}