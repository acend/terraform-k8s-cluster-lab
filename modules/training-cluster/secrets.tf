resource "kubernetes_secret" "hosttech-secret" {

  metadata {
    name      = "hosttech-secret"
    namespace = "cert-manager"
  }

  data = {
    token = var.hosttech_dns_token
  }
}

resource "kubernetes_secret" "hcloud" {
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