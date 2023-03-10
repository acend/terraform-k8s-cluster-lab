output "student-direct-webshelllink" {
  value = nonsensitive("https://${var.student-name}:${var.student-password}@${var.student-name}.${var.cluster_name}.labcluster.acend.ch")
}
