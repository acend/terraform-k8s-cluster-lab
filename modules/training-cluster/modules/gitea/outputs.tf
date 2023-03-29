output "admin-password" {
  value = random_password.admin-password.result
}

output "admin-username" {
  value = "gitea_admin"
}

output "gitea-url" {
  value = "https://gitea.${var.cluster_name}.${var.cluster_domain}"
}