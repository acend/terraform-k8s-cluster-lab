resource "kubernetes_secret" "hosttech-secret" {
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