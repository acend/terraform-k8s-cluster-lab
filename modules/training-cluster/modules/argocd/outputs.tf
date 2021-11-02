output "admin-secret" {
  value = data.kubernetes_secret.admin-secret.data
}

output "student-password" {
  value = nonsensitive(data.kubernetes_secret.admin-secret.data)
}