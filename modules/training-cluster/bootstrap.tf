// Register the Cluster on the bootstraping ArgoCD
resource "time_sleep" "wait_for_bootstrap_removal" {
  depends_on = [null_resource.wait_for_k8s_api]

  destroy_duration = "180s"
}


resource "kubernetes_secret" "argocd-cluster" {
  provider = kubernetes.acend

  depends_on = [
    time_sleep.wait_for_bootstrap_removal,
    module.api-a-record,
    module.api-aaaa-record
  ]

  metadata {
    name      = var.cluster_name
    namespace = "argocd"

    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
      "flavor"                         = "k8s"
      "type"                           = "training"
    }
  }

  data = {
    name   = "${var.cluster_name}.${var.cluster_domain}"
    server = "https://api.${var.cluster_name}.${var.cluster_domain}:6443"
    config = jsonencode({
      tlsClientConfig = {
        caData   = local.kubeconfig.clusters[0].cluster.certificate-authority-data
        certData = local.kubeconfig.users[0].user.client-certificate-data
        keyData  = local.kubeconfig.users[0].user.client-key-data
      }
    })
  }

  type = "Opaque"
}

// Create a secret with credentials for external secrets to be used in SecretStore for bootstrapng
resource "kubernetes_secret" "secretstore-secret" {
  provider = kubernetes.acend

  depends_on = [
    null_resource.wait_for_k8s_api
  ]

  metadata {
    name      = "credentials-${var.cluster_name}.${var.cluster_domain}"
    namespace = "external-secrets"
  }

  data = {
    cert = base64decode(local.kubeconfig.users[0].user.client-certificate-data)
    key  = base64decode(local.kubeconfig.users[0].user.client-key-data)
    ca   = base64decode(local.kubeconfig.clusters[0].cluster.certificate-authority-data)
  }

  type = "Opaque"
}

locals {
  secretStore_namespaces = toset([
    "kube-system",
    "cert-manager"
  ])
}

// Deploy a Secret Store for each Namespace the external-secrets operator shall push secrets to
resource "kubernetes_manifest" "external-secrets-secretstore" {

  depends_on = [
    kubernetes_secret.secretstore-secret
  ]

  for_each = local.secretStore_namespaces

  provider = kubernetes.acend
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ClusterSecretStore"
    "metadata" = {
      "name" = "cluster-${var.cluster_name}.${var.cluster_domain}-${each.key}"
    }
    "spec" = {
      "provider" = {
        "kubernetes" = {
          "remoteNamespace" = each.key
          "server" = {
            "url" = "https://api.${var.cluster_name}.${var.cluster_domain}:6443"
            "caProvider" = {
              "type"      = "Secret"
              "name"      = "credentials-${var.cluster_name}.${var.cluster_domain}"
              "key"       = "ca"
              "namespace" = "external-secrets"
            }
          }

          "auth" = {
            "cert" = {
              "clientCert" = {
                "name"      = "credentials-${var.cluster_name}.${var.cluster_domain}"
                "key"       = "cert"
                "namespace" = "external-secrets"
              },
              "clientKey" = {
                "name"      = "credentials-${var.cluster_name}.${var.cluster_domain}"
                "key"       = "key"
                "namespace" = "external-secrets"
              }
            }
          }
        }
      }
    }
  }
}