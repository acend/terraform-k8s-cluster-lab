resource "rancher2_namespace" "student-namespace" {

  name       = var.student-name
  project_id = var.rancher_training_project.id

  labels = {
      certificate-labapp = "true"
  }
}

resource "random_password" "basic-auth-password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "helm_release" "webshell" {

  depends_on = [rancher2_namespace.student-namespace]


  name       = "webshell"
  chart      = var.chart-repository
  namespace  = rancher2_namespace.student-namespace.name

  set {
    name  = "student"
    value = var.student-name
  }

  set {
    name = "password"
    value = random_password.basic-auth-password.result
  }

  set {
    name = "ingress.enabled"
    value = "true"
  }

  set {
    name = "ingress.className"
    value = "nginx"
  }

  set {
    name = "ingress.annotations.ingress\\.kubernetes\\.io/ssl-redirect"
    value = "true"
  }

  set {
    name = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-type"
    value = "basic"
  }

  set {
    name = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-secret"
    value = "basic-auth"
  }

  set {
    name = "ingress.hosts[0].host"
    value = "${var.student-name}.${var.domain}"
  }

  set {
    name = "ingress.hosts[0].paths[0].path"
    value = "/"
  }

  set {
    name = "ingress.hosts[0].paths[0].pathType"
    value = "ImplementationSpecific"
  }

  set {
    name = "ingress.tls[0].secretName"
    value = "labapp-wildcard"
  }

  set {
    name = "ingress.tls[0].hosts[0]"
    value = "${var.student-name}.${var.domain}"
  }


}
