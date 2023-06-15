resource "kubernetes_namespace" "ingress-nginx" {

  depends_on = [
    time_sleep.wait_for_cluster_ready
  ]
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "ingress-haproxy" {

  depends_on = [
    time_sleep.wait_for_cluster_ready
  ]
  metadata {
    name = "ingress-haproxy"
  }
}

resource "helm_release" "ingress-nginx" {

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.6.1"
  namespace  = kubernetes_namespace.ingress-nginx.metadata[0].name

  set {
    name  = "controller.replicaCount"
    value = "2"
  }

  set {
    name  = "controller.ingressClassResource.default"
    value = true
  }

  set {
    name  = "controller.extraArgs.default-ssl-certificate"
    value = "cert-manager/acend-wildcard"
  }

}

data "kubernetes_service" "ingress-nginx" {

  depends_on = [
    helm_release.ingress-nginx
  ]
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress-nginx.metadata[0].name
  }

}

resource "helm_release" "ingress-haproxy" {

  name       = "ingress-haproxy"
  repository = "https://haproxy-ingress.github.io/charts"
  chart      = "ingress-haproxy"
  version    = "0.14.3"
  namespace  = kubernetes_namespace.ingress-haproxy.metadata[0].name

  set {
    name  = "controller.replicaCount"
    value = "2"
  }

  set {
    name  = "controller.ingressClassResource.enabled"
    value = true
  }

  set {
    name  = "controller.extraArgs.default-ssl-certificate"
    value = "cert-manager/acend-wildcard"
  }

}