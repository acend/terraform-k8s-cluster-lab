resource "kubernetes_secret" "hosttech-secret" {

  metadata {
    name      = "hosttech-secret"
    namespace = "cert-manager"
  }

  data = {
    token = var.hosttech_dns_token
  }
}