provider "restapi" {
  alias                = "gitea"
  uri                  = "https://gitea.${var.cluster_name}.${var.cluster_domain}"
  write_returns_object = true
  username             = "gitea_admin"
  password             = random_password.gitea-admin-password.result
}

resource "kubernetes_namespace" "gitea" {

  depends_on = [
    time_sleep.wait_for_cluster_ready,
  ]

  metadata {
    name = "gitea"

    labels = {
      certificate-labapp            = "true"
      "kubernetes.io/metadata.name" = "gitea"
    }
  }
}

# Create admin password for gitea admin
resource "random_password" "gitea-admin-password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# Create pg password for gitea postgresdb
resource "random_password" "gitea-pg-password" {
  length           = 16
  special          = true
  override_special = "_%@"
}


resource "helm_release" "gitea" {

  depends_on = [ 
    helm_release.hcloud-csi-driver # for storage
   ]


  name       = "gitea"
  repository = "https://dl.gitea.io/charts/"
  chart      = "gitea"
  namespace  = kubernetes_namespace.gitea.metadata.0.name


  set {
    name  = "global.storageClass"
    value = "hcloud-volume"
  }

  set {
    name  = "gitea.admin.password"
    value = random_password.gitea-admin-password.result
  }

  set {
    name  = "gitea.postgresql.global.postgresql.postgresqlPassword"
    value = random_password.gitea-pg-password.result
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.className"
    value = "haproxy"
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


// Wait until gitea is really ready
resource "time_sleep" "wait_30_seconds" {
  depends_on = [helm_release.gitea]

  create_duration = "30s"
}


resource "restapi_object" "gitea-user" {
  depends_on = [
    time_sleep.wait_30_seconds
  ]


  provider  = restapi.gitea
  path      = "/api/v1/admin/users"
  read_path = "/api/v1/users/{id}"

  data = (jsonencode({
    email                = "${var.studentname-prefix}${count.index + 1}@gitea.${var.cluster_name}.${var.cluster_domain}"
    full_name            = "${var.studentname-prefix}${count.index + 1}"
    login_name           = "${var.studentname-prefix}${count.index + 1}"
    must_change_password = false
    password             = random_password.student-passwords[count.index].result
    send_notify          = false
    source_id            = 0
    username             = "${var.studentname-prefix}${count.index + 1}"
    visibility           = "public"
  }))
  id_attribute = "username"
  count        = var.count-students
}


resource "restapi_object" "gitea-repo" {

  provider     = restapi.gitea
  path         = "/api/v1/repos"
  create_path  = "/api/v1/repos/migrate"

  data = (jsonencode({
    clone_addr = "https://github.com/acend/argocd-training-examples.git"
    private    = false
    repo_name  = "argocd-training-examples"
    repo_owner = restapi_object.gitea-user[count.index].api_data.username

  }))
  id_attribute = "full_name"

  count = var.count-students
}

