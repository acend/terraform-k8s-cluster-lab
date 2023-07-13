resource "kubernetes_secret" "hosttech-secret" {
  provider = kubernetes.local

  depends_on = [
    null_resource.wait_for_k8s_api
  ]
  metadata {
    name      = "hosttech-secret"
    namespace = "kube-system"
    annotations = {
      "kubed.appscode.com/sync" = "app=cert-manager"
    }
  }

  data = {
    token = var.hosttech_dns_token
  }
}

resource "kubernetes_secret" "hcloud" {
  provider = kubernetes.local

  depends_on = [
    null_resource.wait_for_k8s_api
  ]
  metadata {
    name      = "hcloud"
    namespace = "kube-system"
  }

  data = {
    token          = var.hcloud_api_token
    network        = hcloud_network.network.id
    hcloudApiToken = var.hcloud_api_token
  }

  type = "Opaque"
}

resource "kubernetes_secret" "argocd-cluster" {
  provider = kubernetes.acend

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

resource "kubernetes_secret" "secretstore-secret" {
  provider = kubernetes.acend

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
resource "kubernetes_manifest" "external-secrets-secretstore" {

  provider = kubernetes.acend
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "SecretStore"
    "metadata" = {
      "name"      = "cluster-${var.cluster_name}.${var.cluster_domain}"
      "namespace" = "external-secrets"
    }
    "spec" = {
      "provider" = {
        "kubernetes" = {
          "server" = {
            "url" = "https://api.${var.cluster_name}.${var.cluster_domain}:6443"
            "caProvider" = {
              "type"      = "Secret"
              "name"      = "credentials-${var.cluster_name}.${var.cluster_domain}"
              "key"       = "ca"
            }
          }

          "auth" = {
            "cert" = {
              "clientCert" = {
                "name"      = "credentials-${var.cluster_name}.${var.cluster_domain}"
                "key"       = "cert"
              },
              "clientKey" = {
                "name"      = "credentials-${var.cluster_name}.${var.cluster_domain}"
                "key"       = "key"
              }
            }
          }
        }
      }
    }
  }
}