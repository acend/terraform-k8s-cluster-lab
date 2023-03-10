resource "helm_release" "cluster-autoscaler" {

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
