variable "student_name" {
    type = string
}

variable "student_password" {
    type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_domain" {
  type = string
}

resource "restapi_object" "gitea-user" {

  path      = "/api/v1/admin/users"
  read_path = "/api/v1/users/{id}"

  data = (jsonencode({
    email                = "${var.student_name}@gitea.${var.cluster_name}.${var.cluster_domain}"
    full_name            = var.student_name
    login_name           = var.student_name
    must_change_password = false
    password             = var.student_password
    send_notify          = false
    source_id            = 0
    username             = var.student_name
    visibility           = "public"
  }))
  id_attribute = "username"
}


resource "restapi_object" "gitea-repo" {

  path         = "/api/v1/repos"
  create_path  = "/api/v1/repos/migrate"

  data = (jsonencode({
    clone_addr = "https://github.com/acend/argocd-training-examples.git"
    private    = false
    repo_name  = "argocd-training-examples"
    repo_owner = restapi_object.gitea-user.api_data.username

  }))
  id_attribute = "full_name"

}

