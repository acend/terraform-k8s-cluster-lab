output "kubeconfig_raw" {
  value     = local.kubeconfig_raw
  sensitive = true
}

output "argocd-admin-username" {
  value = "admin"
}

output "argocd-admin-password" {
  value = random_password.argocd-admin-password.result
}

output "argocd-url" {
  value = "https://argocd.${var.cluster_name}.${var.cluster_domain}"
}

output "student-passwords" {
  value     = random_password.student-passwords
  sensitive = true
}

output "count-students" {
  value = var.count-students
}

output "studentname-prefix" {
  value = var.studentname-prefix
}