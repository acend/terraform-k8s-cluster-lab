# Deploy Cert-Manager for Certificates

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "certmanager" {

  name       = "certmanager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.11.0"
  namespace  = kubernetes_namespace.cert-manager.metadata[0].name

  set {
    name  = "installCRDs"
    value = true
  }

  set {
    name  = "ingressShim.defaultIssuerName"
    value = "letsencrypt-prod"
  }

  set {
    name  = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }

}

resource "helm_release" "certmanager-webhook-hosttech" {

  depends_on = [
    helm_release.certmanager
  ]

  name       = "cert-manager-webhook-hosttech"
  repository = "https://piccobit.github.io/helm-charts"
  chart      = "cert-manager-webhook-hosttech"
  version    = "0.3.0"
  namespace  = kubernetes_namespace.cert-manager.metadata[0].name

  set {
    name  = "groupName"
    value = "acme.acend.ch"
  }

  set {
    name = "certManager.serviceAccountName"
    value = "certmanager-cert-manager"
  }

}



# For Secret/Certificate sync across Namespaces
resource "helm_release" "kubed" {

  name       = "config-syncer"
  repository = "https://charts.appscode.com/stable/"
  chart      = "config-syncer"
  version    = "v0.14.0-rc.0"
  namespace  = "kube-system"

}

resource "kubernetes_manifest" "clusterissuer-letsencrypt-prod" {
  depends_on = [
    helm_release.certmanager
  ]

  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-prod"
    }

    "spec" = {
      "acme" = {
        "email" = var.letsencrypt_email
        "privateKeySecretRef" = {
          "name" = "letsencrypt-prod"
        }
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [{
          "http01" = {
            "ingress" = {
              "class" = "nginx"
            }
          }
        }]
      }
    }
  }
}

resource "kubernetes_manifest" "clusterissuer-acend-hosttech" {
  depends_on = [
    helm_release.certmanager
  ]

  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-prod-acend"
    }

    "spec" = {
      "acme" = {
        "email" = var.letsencrypt_email
        "privateKeySecretRef" = {
          "name" = "letsencrypt-prod-acend"
        }
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [{
          "selector" = {
            "dnsNames" = [
              "*.${var.cluster_name}.labcluster.acend.ch"
            ]
          }
          "dns01" = {
            "webhook" = {
              "groupName" = "acme.acend.ch"
              "solverName" = "hosttech"
              "config" = {
                "secretName" = "hosttech-secret"
                "apiUrl" = "https://api.ns1.hosttech.eu/api/user/v1"
              }
            }
          }
        }]
      }
    }
  }
}

resource "kubernetes_manifest" "certificate-acend-wildcard" {
  depends_on = [
    helm_release.certmanager
  ]

  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "acend-wildcard"
      "namespace" = kubernetes_namespace.cert-manager.metadata[0].name
    }

    "spec" = {
      "dnsNames" = [
        "*.${var.cluster_name}.labcluster.acend.ch"
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt-prod-acend"
      }
      "secretName" = "acend-wildcard"
      "secretTemplate" = {
        "annotations" = {
          "kubed.appscode.com/sync" = "certificate-wildcard=true"
        }
      }    
    }
  }
}

resource "kubernetes_secret" "hosttech-secret" {
  metadata {
    name      = "hosttech-secret"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
  }

  data = {
    token = var.hosttech_dns_token
  }

}
