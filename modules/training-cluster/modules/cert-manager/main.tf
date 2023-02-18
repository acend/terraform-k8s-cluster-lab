resource "rancher2_namespace" "cert-manager" {

  name       = "cert-manager"
  project_id = var.rancher_system_project.id
}

locals {
  cert-manager-namespace = rancher2_namespace.cert-manager.name
}

resource "helm_release" "certmanager" {

  depends_on = [rancher2_namespace.cert-manager]


  name       = "certmanager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version
  namespace  = local.cert-manager-namespace

  set {
    name  = "installCRDs"
    value = true
  }

  set {
    name  = "ingressShim.defaultIssuerName"
    value = "letsencrypt-prod"
  }

  set {
    name  = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }

}

resource "helm_release" "certmanager-webhook-hosttech" {

  depends_on = [rancher2_namespace.cert-manager]


  name       = "cert-manager-webhook-hosttech"
  repository = "https://piccobit.github.io/helm-charts"
  chart      = "cert-manager-webhook-hosttech"
  version    = "0.3.0"
  namespace  = local.cert-manager-namespace

  set {
    name  = "groupName"
    value = "acme.acend.ch"
  }

}



# For Secret/Certificate sync across Namespaces
resource "helm_release" "kubed" {

  depends_on = [rancher2_namespace.cert-manager]


  name       = "config-syncer"
  repository = "https://charts.appscode.com/stable/"
  chart      = "config-syncer"
  version    = "v0.14.0-rc.0"
  namespace  = "kube-system"

}

resource "k8s_manifest" "clusterissuer-letsencrypt-prod" {

  depends_on = [helm_release.certmanager]

  content = templatefile("${path.module}/manifests/letsencrypt-prod.yaml", { letsencrypt_email = var.letsencrypt_email })
}

resource "k8s_manifest" "clusterissuer-acend-acme" {

  depends_on = [helm_release.certmanager, kubernetes_secret.hosttech-secret]

  content = templatefile("${path.module}/manifests/clusterissuer-acend-acme.yaml", {})
}

resource "k8s_manifest" "certificate-acend-labapp-wildcard" {

  depends_on = [helm_release.certmanager, k8s_manifest.clusterissuer-acend-acme]

  content = templatefile("${path.module}/manifests/certificate-wildcard-labapp.yaml", {})
}

resource "kubernetes_secret" "hosttech-secret" {
  metadata {
    name      = "hosttech-secret"
    namespace = local.cert-manager-namespace
  }

  data = {
    token = var.hosttech_dns_token
  }

}