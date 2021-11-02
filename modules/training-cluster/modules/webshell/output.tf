output "student-direct-webshelllink" {
  value = nonsensitive("https://${var.student-name}:${var.student-password}@${var.student-name}.${var.domain}")
}
