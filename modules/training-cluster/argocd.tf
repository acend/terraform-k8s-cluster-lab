
resource "kubernetes_namespace" "argocd" {

  provider = kubernetes.local

  depends_on = [
    null_resource.wait_for_k8s_api
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

  depends_on = [
    time_sleep.wait_for_bootstrap_removal
  ]

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
    templatefile("${path.module}/manifests/argocd/values.yaml", { cluster_name = var.cluster_name, cluster_domain = var.cluster_domain }),
  ]

}