output "kubeconfig_raw" {
  value = local.kubeconfig_raw
}

output "webshell-links" {
  value = module.webshell.*.student-direct-webshelllink
}

output "argocd-admin-secret" {
  value = var.argocd-enabled ? module.argocd[0].admin-secret : ""
}
output "gitea-admin-password" {
  value = var.gitea-enabled ? module.gitea[0].admin-password : ""
}

output "student-vm-ip-address" {
  value = var.user-vms-enabled ? module.student-vms[0].ip-address : []
}