resource "kubernetes_cluster_role_binding" "cluster-admin" {
  provider = kubernetes.local

  depends_on = [
    time_sleep.wait_for_cluster_ready
  ]

  metadata {
    name = "webshell-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  dynamic "subject" {
    for_each = var.cluster_admin
    content {
      kind      = "ServiceAccount"
      name      = "webshell"
      namespace = subject.value
    }
  }

  count = length(var.cluster_admin) > 0 ? 1 : 0

}