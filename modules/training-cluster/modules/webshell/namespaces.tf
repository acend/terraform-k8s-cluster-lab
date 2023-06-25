// Main Namespace

resource "kubernetes_namespace" "student" {
  metadata {
    name = var.student-name
    labels = {
      certificate-wildcard          = "true" # this will copy the wildcard cert created with cert-manager using the kubed installation
      "kubernetes.io/metadata.name" = var.student-name
    }
  }
}

// Namespace + Resources for CKB Quotalab

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