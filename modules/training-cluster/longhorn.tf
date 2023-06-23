resource "kubernetes_namespace" "longhorn-system" {
  metadata {
    name = "longhorn-system"
    labels = {
      "kubernetes.io/metadata.name" = "longhorn-system"
    }
  }
}

resource "helm_release" "longhorn" {
  depends_on = [
    time_sleep.wait_for_cluster_ready
  ]

  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.4.2"
  namespace  = kubernetes_namespace.longhorn-system.metadata.0.name

  values = [
    "${templatefile("${path.module}/manifests/longhorn-values.yaml", {})}"
  ]
}
