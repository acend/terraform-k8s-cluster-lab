resource "helm_release" "cluster-autoscaler" {

  depends_on = [
    time_sleep.wait_for_cluster_ready
  ]

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.25.0"
  namespace  = "kube-system"

  values = [
    "${templatefile("${path.module}/manifests/cluster-autoscaler-values.yaml", {
    cluster_name = var.cluster_name})}"
  ]
}
