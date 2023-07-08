
resource "time_sleep" "wait_30_seconds" {
  depends_on = [helm_release.gitea]

  create_duration = "30s"
}


resource "restapi_object" "gitea-user" {
  depends_on = [
    time_sleep.wait_30_seconds
  ]


  provider     = restapi.gitea
  path         = "/api/v1/admin/users"
  data         = "${jsonencode({
    email = "${var.studentname-prefix}${count.index + 1}@gitea.${var.cluster_name}.${var.cluster_domain}"
    full_name = "${var.studentname-prefix}${count.index + 1}"
    login_name = "${var.studentname-prefix}${count.index + 1}"
    must_change_password = false
    password = random_password.student-passwords[count.index].result
    send_notify = false
    source_id = 0
    username = "${var.studentname-prefix}${count.index + 1}"
    visibility = "public"
    })
    }"
  id_attribute = "username"
  count = var.count-students
}


resource "restapi_object" "gitea-repo" {
  depends_on = [
    restapi_object.gitea-user
  ]


  provider     = restapi.gitea
  path         = "/api/v1/repo/{repo_owner}/{id}"
  create_path  = "/api/v1/repos/migrate"
  destroy_path = "/api/v1/repo/{repo_owner}/{id}"
  data         = "${jsonencode({
    clone_addr = "https://github.com/acend/argocd-training-examples.git"
    private = false
    repo_name = "argocd-training-examples"
    repo_owner = "${var.studentname-prefix}${count.index + 1}"

    })
    }"
  id_attribute = "repo_name"

  count = var.count-students
}

