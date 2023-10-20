resource "helm_release" "appset-trainee-env" {

  count = var.count-students > 0 ? 1 : 0

  depends_on = [
    helm_release.argocd
  ]

  name       = "trainee-env"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = kubernetes_namespace.argocd.metadata.0.name
  version    = "1.4.1"


  values = [
    templatefile("${path.module}/manifests/argocd/values_appset-trainee-env.yaml", {
      studentname-prefix = var.studentname-prefix,
      count-students     = var.count-students,
      cluster_name       = var.cluster_name,
      cluster_domain     = var.cluster_domain,
      passwords          = random_password.student-passwords,
      cluster_admin      = var.cluster_admin
    }),
  ]

}

resource "helm_release" "appset-trainee-webshell" {

  count = var.count-students > 0 ? 1 : 0

  depends_on = [
    helm_release.argocd
  ]

  name       = "trainee-webshell"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = kubernetes_namespace.argocd.metadata.0.name
  version    = "1.4.1"


  values = [
    templatefile("${path.module}/manifests/argocd/values_appset-trainee-webshell.yaml",
      {
        studentname-prefix        = var.studentname-prefix,
        count-students            = var.count-students,
        cluster_name              = var.cluster_name,
        cluster_domain            = var.cluster_domain,
        passwords                 = random_password.student-passwords,
        rbac-enabled              = var.webshell-settings.webshell-rbac-enabled,
        dind-persistence-enabled  = var.webshell-settings.dind-persistence-enabled,
        theia-persistence-enabled = var.webshell-settings.theia-persistence-enabled
        user-vm-enabled           = var.user-vms-enabled
        ipv4-address              = var.user-vms-enabled ? module.student-vms[0].ip-address : ""
        ipv6-address              = var.user-vms-enabled ? module.student-vms[0].ipv6-address : ""
        ssh-keys                  = var.user-vms-enabled ? module.student-vms[0].user-ssh-keys : ""

        dind_resources  = var.webshell-settings.dind_resources
        theia_resources = var.webshell-settings.theia_resources
        version         = var.webshell-settings.version
    }),
  ]

} 