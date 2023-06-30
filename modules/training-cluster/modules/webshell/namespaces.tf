// Default student Namespace

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
    namespace = kubernetes_namespace.student.metadata.0.name
  }

  count = var.rbac-enabled ? 1 : 0
}


# Namespaces for ArgoCD Training
# Student Prod Namespaces
resource "kubernetes_namespace" "student-namespace-prod" {

  metadata {
    name = "${var.student-name}-prod"

    labels = {
      certificate-wildcard          = "true"
      "kubernetes.io/metadata.name" = "${var.student-name}-prod"
    }
  }
}


// Allow to use the SA from Webshell Namespace to also access this argocd student prod Namespace
resource "kubernetes_role_binding" "student-prod" {


  metadata {
    name      = "admin-rb"
    namespace = kubernetes_namespace.student-namespace-prod.metadata.0.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "webshell"
    namespace = kubernetes_namespace.student.metadata.0.name
  }

}

resource "kubernetes_role_binding" "argocd-prod" {
  metadata {
    name      = "argocd-rb"
    namespace = kubernetes_namespace.student-namespace-prod.metadata.0.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "argocd"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "webshell"
    namespace = kubernetes_namespace.student.metadata.0.name
  }

}

# Student Dev Namespaces
resource "kubernetes_namespace" "student-namespace-dev" {

  metadata {
    name = "${var.student-name}-dev"

    labels = {
      certificate-labapp            = "true"
      "kubernetes.io/metadata.name" = "${var.student-name}-dev"
    }
  }

}


// Allow to use the SA from Webshell Namespace to also access this argocd student prod Namespace
resource "kubernetes_role_binding" "student-dev" {
  metadata {
    name      = "admin-rb"
    namespace = kubernetes_namespace.student-namespace-dev.metadata.0.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "webshell"
    namespace = kubernetes_namespace.student.metadata.0.name
  }

}

resource "kubernetes_role_binding" "argocd-dev" {
  metadata {
    name      = "argocd-rb"
    namespace = kubernetes_namespace.student-namespace-dev.metadata.0.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "argocd"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "webshell"
    namespace = kubernetes_namespace.student.metadata.0.name
  }
}


# Student  Namespaces
resource "kubernetes_role_binding" "argocd" {
  metadata {
    name      = "argocd-rb"
    namespace = kubernetes_namespace.student.metadata.0.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "argocd"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "webshell"
    namespace = kubernetes_namespace.student.metadata.0.name
  }
}

// Allow access to argocd resrouces in argocd namespace
resource "kubernetes_role_binding" "argocd-app" {
  metadata {
    name      = "argocd-app-${var.student-name}-rb"
    namespace = var.argocd_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "argocd"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "webshell"
    namespace = kubernetes_namespace.student.metadata.0.name
  }
}