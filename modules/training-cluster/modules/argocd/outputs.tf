output "admin-secret" {
  value = data.kubernetes_secret.admin-secret.data.password
}

output "student-password" {
  value = nonsensitive(random_password.student-password.*.result)
}