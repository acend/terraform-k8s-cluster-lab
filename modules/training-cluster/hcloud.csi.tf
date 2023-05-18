resource "helm_release" "hcloud-csi-driver" {

  depends_on = [
    time_sleep.wait_for_cluster_ready
  ]

  name       = "hcloud-csi-driver"
  repository = "https://helm-charts.mlohr.com/"
  chart      = "hcloud-csi-driver"
  version    = "2.2.1"
  namespace  = "kube-system"

  set {
    name  = "secret.existingSecretName"
    value = "hcloud"
  }
}
