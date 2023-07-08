output "student-direct-webshelllink" {
  value = nonsensitive("https://${var.student-name}:${var.student-password}@${var.student-name}.${var.cluster_name}.${split(".", var.cluster_domain)[0]}.acend.ch")
}

output "student-name" {
  value = var.student-name
}

output "student-password" {
  value = var.student-password
}