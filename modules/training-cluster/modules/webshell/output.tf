output "student-password" {
  value = random_password.basic-auth-password.result
}

output "student-username" {
  value = var.student-name
}
