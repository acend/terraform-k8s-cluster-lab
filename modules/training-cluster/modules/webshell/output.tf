output "student-password" {
  value = random_password.basic-auth-password.result
}

output "student-username" {
  value = var.student-name
}

output "student-direct-webshelllink" {
  value = "https://${var.student-name}:${random_password.basic-auth-password.result}@${var.student-name}.${var.domain}"
}
