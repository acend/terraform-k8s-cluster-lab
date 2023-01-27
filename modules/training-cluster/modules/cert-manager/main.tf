resource "rancher2_namespace" "cert-manager" {

  name       = "cert-manager"
  project_id = var.rancher_system_project.id
}

resource "helm_release" "certmanager" {

  depends_on = [rancher2_namespace.cert-manager]


  name       = "certmanager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version
  namespace  = "cert-manager"

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

resource "k8s_manifest" "secret-acend-acme" {

  depends_on = [helm_release.certmanager]

  content = templatefile("${path.module}/manifests/secret-acme.yaml", { acme-config = var.acme-config })
}


resource "k8s_manifest" "clusterissuer-acend-acme" {

  depends_on = [helm_release.certmanager, k8s_manifest.secret-acend-acme]

  content = templatefile("${path.module}/manifests/clusterissuer-acend-acme.yaml", {})
}

resource "k8s_manifest" "certificate-acend-labapp-wildcard" {

  depends_on = [helm_release.certmanager, k8s_manifest.clusterissuer-acend-acme]

  content = templatefile("${path.module}/manifests/certificate-wildcard-labapp.yaml", {})
}