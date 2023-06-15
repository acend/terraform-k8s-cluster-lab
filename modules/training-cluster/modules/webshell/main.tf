resource "kubernetes_namespace" "student" {

  metadata {
    name = var.student-name
    labels = {
      certificate-wildcard          = "true" # this will copy the wildcard cert created with cert-manager using the kubed installation
      "kubernetes.io/metadata.name" = var.student-name
    }
  }

}

resource "kubernetes_namespace" "student-quotalab" {

  metadata {
    name = "${var.student-name}-quota"
  }
}

resource "kubernetes_resource_quota" "quotalab" {
  metadata {
    name      = "lab-quota"
    namespace = kubernetes_namespace.student-quotalab.metadata.0.name
  }
  spec {
    hard = {
      "requests.cpu"    = "100m"
      "requests.memory" = "100Mi"
    }
  }
}

resource "kubernetes_limit_range" "quotalab" {
  metadata {
    name      = "lab-limitrange"
    namespace = kubernetes_namespace.student-quotalab.metadata.0.name
  }
  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "100m"
        memory = "32Mi"
      }
      default_request = {
        cpu    = "10m"
        memory = "16Mi"
      }
    }

  }
}

// Allow to use the SA from Webshell Namespace to also access this quotalab student prod Namespace
resource "kubernetes_role_binding" "student-quotalab" {
  metadata {
    name      = "admin-rb"
    namespace = kubernetes_namespace.student-quotalab.metadata.0.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "webshell"
    namespace = var.student-name
  }

  count = var.rbac-enabled ? 1 : 0

}

resource "helm_release" "webshell" {


  name       = "webshell"
  repository = var.chart-repository
  chart      = "webshell"
  version    = var.chart-version
  namespace  = kubernetes_namespace.student.metadata.0.name

  values = [
    "${templatefile(
      "${path.module}/manifests/values.yaml",
      {
        user-vm-enabled = var.user-vm-enabled
        student-index   = var.student-index

        student-name    = var.student-name
        ip-address      = var.user-vm-enabled ? var.student-vms[0].ip-address[var.student-index] : ""
        ssh-public-key  = var.user-vm-enabled ? chomp(var.student-vms[0].user-ssh-keys[var.student-index].public_key_openssh) : ""
        ssh-private-key = var.user-vm-enabled ? base64encode(var.student-vms[0].user-ssh-keys[var.student-index].private_key_pem) : ""
      }
    )}"
  ]

  set {
    name  = "user"
    value = var.student-name
  }

  set {
    name  = "password"
    value = var.student-password
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.className"
    value = "haproxy"
  }

  set {
    name  = "ingress.annotations.ingress\\.kubernetes\\.io/ssl-redirect"
    value = "true"
    type  = "string"
  }

  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-type"
    value = "basic-auth"
  }

  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-secret"
    value = "${kubernetes_namespace.student.metadata.0.name}/basic-auth"
  }

  set {
    name  = "ingress.hosts[0].host"
    value = "${var.student-name}.${var.cluster_name}.${var.cluster_domain}"
  }

  set {
    name  = "ingress.hosts[0].paths[0].path"
    value = "/"
  }

  set {
    name  = "ingress.hosts[0].paths[0].pathType"
    value = "ImplementationSpecific"
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "acend-wildcard"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = "${var.student-name}.${var.cluster_name}.labcluster.acend.ch"
  }

  set {
    name  = "theia.persistence.enabled"
    value = tostring(var.theia-persistence-enabled)

  }

  set {
    name  = "theia.persistence.storageclass"
    value = "longhorn"
  }

  set {
    name  = "podSecurityContext.fsGroup"
    value = "1001"
  }

  set {
    name  = "updateStrategy.type"
    value = "Recreate"
  }

  set {
    name  = "dind.persistence.enabled"
    value = tostring(var.dind-persistence-enabled)
  }

  set {
    name  = "dind.persistence.storageclass"
    value = "hcloud-volume"
  }

  set {
    name  = "dind.persistence.pvcsize"
    value = "10Gi"
  }

  set {
    name  = "rbac.create"
    value = tostring(var.rbac-enabled)
  }


}
