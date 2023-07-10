resource "kubernetes_secret" "hosttech-secret" {

  metadata {
    name      = "hosttech-secret"
    namespace = kubernetes_namespace.cert-manager.metadata[0].name
  }

  data = {
    token = var.hosttech_dns_token
  }
}