
resource "rancher2_namespace" "argocd-namespace" {

  name       = "argocd"
  project_id = var.rancher_training_project.id

  labels = {
      certificate-labapp = "true"
  }
}

data "kubernetes_secret" "admin-secret" {
  metadata {
    name = "argocd-initial-admin-secret"
    namespace = rancher2_namespace.argocd-namespace.name
  }

  depends_on = [
    helm_release.argocd
  ]
}

resource "helm_release" "argocd" {


  name       = "argocd"
  repository = var.chart-repository
  chart      = "argo-cd"
  namespace  = rancher2_namespace.argocd-namespace.name


  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  set {
    name  = "server.metrics.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.labapp.acend.ch"
  }

  set {
    name = "server.ingress.tls[0].hosts[0]"
    value = "argocd.labapp.acend.ch"
  }

  set {
    name = "server.ingress.tls[0].secretName"
    value = "labapp-wildcard"
  }

  set {
    name = "server.ingress.https"
    value = "true"
  }

  set {
    name = "server.ingressGrpc.enabled"
    value = "true"
  }

  set {
    name = "server.ingressGrpc.hosts[0]"
    value = "argocd-grpc.labapp.acend.ch"
  }

  set {
    name = "server.ingressGrpc.tls[0].hosts[0]"
    value = "argocd-grpc.labapp.acend.ch"
  }

  set {
    name = "server.ingressGrpc.tls[0].secretName"
    value = "labapp-wildcard"
  }

    set {
    name = "server.ingressGrpc.https"
    value = "true"
  }



}