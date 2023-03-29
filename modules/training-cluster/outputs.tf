output "kubeconfig_raw" {
  value = local.kubeconfig_raw
}

output "webshell-links" {
  value = module.webshell.*.student-direct-webshelllink
}

output "argocd-admin-username" {
  value = var.argocd-enabled ? module.argocd[0].admin-username : ""
}

output "argocd-admin-password" {
  value = var.argocd-enabled ? module.argocd[0].admin-password : ""
}

output "argocd-url" {
  value = var.argocd-enabled ? module.argocd[0].argocd-url : ""
}

output "gitea-admin-password" {
  value = var.gitea-enabled ? module.gitea[0].admin-password : ""
}

output "gitea-admin-username" {
  value = var.gitea-enabled ? module.gitea[0].admin-username : ""
}

output "gitea-url" {
  value = var.gitea-enabled ? module.gitea[0].gitea-url : ""
}

output "student-vm-ip-address" {
  value = var.user-vms-enabled ? module.student-vms[0].ip-address : []
}