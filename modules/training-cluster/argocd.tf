
resource "kubernetes_namespace" "argocd" {

  provider = kubernetes.local

  depends_on = [
    time_sleep.wait_for_cluster_ready,
  ]

  metadata {
    name = "argocd"

    labels = {
      certificate-wildcard          = "true"
      "kubernetes.io/metadata.name" = "argocd"
    }
  }
}

resource "random_password" "argocd-admin-password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "helm_release" "argocd" {

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata.0.name
  version    = "5.37.1"

  set {
    name  = "configs.cm.url"
    value = "https://argocd.${var.cluster_name}.${var.cluster_domain}"
  }

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = random_password.argocd-admin-password.bcrypt_hash
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.${var.cluster_name}.${var.cluster_domain}"
  }

  set {
    name  = "server.ingress.tls[0].hosts[0]"
    value = "argocd.${var.cluster_name}.${var.cluster_domain}"
  }

  set {
    name  = "server.ingressGrpc.hosts[0]"
    value = "argocd-grpc.${var.cluster_name}.${var.cluster_domain}"
  }

  set {
    name  = "server.ingressGrpc.tls[0].hosts[0]"
    value = "argocd-grpc.${var.cluster_name}.${var.cluster_domain}"
  }

  values = [
    templatefile("${path.module}/manifests/argocd/values_account_student.yaml", { studentname-prefix = var.studentname-prefix, count-students = var.count-students, passwords = random_password.student-passwords }),
    templatefile("${path.module}/manifests/argocd/values_rbacConfig_policy.yaml", { studentname-prefix = var.studentname-prefix, count-students = var.count-students, cluster_admin = var.cluster_admin }),
    templatefile("${path.module}/manifests/argocd/values.yaml", {}),
  ]

}

resource "helm_release" "argocd-training-project" {

  depends_on = [
    helm_release.argocd
  ]

  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = kubernetes_namespace.argocd.metadata.0.name
  version    = "1.2.0"


  values = [
    templatefile("${path.module}/manifests/argocd/values_projects.yaml", { studentname-prefix = var.studentname-prefix, count-students = var.count-students }),
  ]

}

resource "helm_release" "argocd-bootstrap" {

  depends_on = [
    helm_release.argocd
  ]

  name       = "argocd-bootstrap"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = kubernetes_namespace.argocd.metadata.0.name
  version    = "1.2.0"

  values = [
    templatefile("${path.module}/manifests/argocd/argocd-bootstrap-values.yaml", {
      namespace = helm_release.argocd.namespace
      overlay   = "${var.cluster_name}.${var.cluster_domain}"
    }),
  ]
}
