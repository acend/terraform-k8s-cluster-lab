
resource "kubernetes_namespace" "gitea" {

  metadata {
    name = "gitea"

    labels = {
      certificate-labapp            = "true"
      "kubernetes.io/metadata.name" = "gitea"
    }
  }
}

# Create admin password for gitea admin
resource "random_password" "admin-password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# Create pg password for gitea postgresdb
resource "random_password" "pg-password" {
  length           = 16
  special          = true
  override_special = "_%@"
}


resource "helm_release" "gitea" {


  name       = "gitea"
  repository = var.chart-repository
  chart      = "gitea"
  namespace  = kubernetes_namespace.gitea.metadata.0.name


  set {
    name  = "global.storageClass"
    value = "hcloud-volume"
  }

  set {
    name  = "gitea.admin.password"
    value = random_password.admin-password.result
  }

  set {
    name  = "gitea.postgresql.global.postgresql.postgresqlPassword"
    value = random_password.pg-password.result
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/force-ssl-redirect"
    value = "true"
    type  = "string"
  }

  set {
    name  = "ingress.hosts[0].host"
    value = "gitea.${var.cluster_name}.${var.cluster_domain}"
  }

  set {
    name  = "ingress.hosts[0].paths[0].path"
    value = "/"
  }

  set {
    name  = "ingress.hosts[0].paths[0].pathType"
    value = "Prefix"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = "gitea.${var.cluster_name}.${var.cluster_domain}"
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "acend-wildcard"
  }

}