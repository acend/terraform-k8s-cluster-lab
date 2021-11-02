output "admin-secret" {
  value = data.kubernetes_secret.admin-secret.data.password
}
