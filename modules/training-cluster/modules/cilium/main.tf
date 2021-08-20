resource "rancher2_namespace" "cilium" {

  name       = "cilium"
  project_id = var.rancher_system_project.id
}


resource "helm_release" "cilium" {

  depends_on = [rancher2_namespace.cilium]


  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = var.chart_version
  namespace  = rancher2_namespace.cilium.name

  set {
    name  = "hubble.ui.enabled"
    value = "true"
  }

  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }

  set {
    name  = "hubble.ui.ingress.enabled"
    value = tostring(var.hubble-ui-ingress-enabled)
  }

  set {
    name  = "hubble.ui.ingress.hosts[0]"
    value = "hubble-ui.${var.public_ip}.xip.puzzle.ch"
  }

  set {
    name  = "hubble.ui.ingress.tls[0].hosts[0]"
    value = "hubble-ui.${var.public_ip}.xip.puzzle.ch"
  }

  set {
    name  = "hubble.ui.ingress.tls[0].secretName"
    value = "hubble-ui-tls-secret"
  }

  set {
    name  = "hubble.ui.ingress.annotations.kubernetes\\.io/tls-acme"
    value = "true"
    type  = "string"
  }



}
