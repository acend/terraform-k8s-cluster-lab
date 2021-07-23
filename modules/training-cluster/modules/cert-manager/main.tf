resource "rancher2_namespace" "cert-manager" {

  name = "cert-manager"
  project_id = var.project_id
}


resource "helm_release" "certmanager" {

  depends_on = [rancher2_namespace.cert-manager]


  name  = "certmanager"
  repository = "https://charts.jetstack.io" 
  chart = "cert-manager"
  version    = var.chart_version
  namespace = "cert-manager"

  set {
    name  = "installCRDs"
    value = true
  }

  set {
    name = "ingressShim.defaultIssuerName"
    value = "letsencrypt-prod"
  }

  set {
    name = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }

}

data "template_file" "clusterissuer-letsencrypt-prod" {
  template = file("${path.module}/manifests/letsencrypt-prod.yaml")

  vars = {
    letsencrypt_email = var.letsencrypt_email
  }
}

resource "k8s_manifest" "clusterissuer-letsencrypt-prod" {
  content = data.template_file.clusterissuer-letsencrypt-prod.rendered
}