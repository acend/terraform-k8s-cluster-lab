output "admin-secret" {
  value = data.kubernetes_secret.admin-secret.data.password
}

output "debug-values" {
  value = nonsensitive(templatefile("${path.module}/manifests/values_account_student.yaml", {count-students = var.count-students, passwords = var.student-passwords}))
}