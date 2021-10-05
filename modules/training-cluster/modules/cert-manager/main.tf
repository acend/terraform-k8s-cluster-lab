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


  name       = "kubed"
  repository = "https://charts.appscode.com/stable/"
  chart      = "kubed"
  version    = "v0.12.0"
  namespace  = "kube-system"

}

data "template_file" "clusterissuer-letsencrypt-prod" {
  template = file("${path.module}/manifests/letsencrypt-prod.yaml")

  vars = {
    letsencrypt_email = var.letsencrypt_email
  }
}

data "template_file" "secret-acme" {
  template = file("${path.module}/manifests/secret-acme.yaml")

  vars = {
    acme-config = var.acme-config
  }
}

data "template_file" "clusterissuer-acend-acme" {
  template = file("${path.module}/manifests/clusterissuer-acend-acme.yaml")
}

data "template_file" "certificate-acend-labapp-wildcard" {
  template = file("${path.module}/manifests/certificate-wildcard-labapp.yaml")
}

resource "k8s_manifest" "clusterissuer-letsencrypt-prod" {

  depends_on = [helm_release.certmanager]

  content = data.template_file.clusterissuer-letsencrypt-prod.rendered
}

resource "k8s_manifest" "secret-acend-acme" {

  depends_on = [helm_release.certmanager]

  content = data.template_file.secret-acme.rendered
}


resource "k8s_manifest" "clusterissuer-acend-acme" {

  depends_on = [helm_release.certmanager, k8s_manifest.secret-acend-acme]

  content = data.template_file.clusterissuer-acend-acme.rendered
}

resource "k8s_manifest" "certificate-acend-labapp-wildcard" {

  depends_on = [helm_release.certmanager, k8s_manifest.clusterissuer-acend-acme]

  content = data.template_file.certificate-acend-labapp-wildcard.rendered
}