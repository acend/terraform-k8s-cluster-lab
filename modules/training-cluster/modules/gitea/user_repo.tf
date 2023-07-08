
resource "time_sleep" "wait_30_seconds" {
  depends_on = [helm_release.gitea]

  create_duration = "30s"
}


resource "null_resource" "giteaUser" {

  depends_on = [
    time_sleep.wait_30_seconds
  ]

  triggers = {
    giteaHost          = "gitea.${var.cluster_name}.${var.cluster_domain}"
    giteaAdminPassword = nonsensitive(random_password.admin-password.result)
    giteaAdminUser     = "gitea_admin"
    password           = nonsensitive(var.student-passwords[count.index].result)
    username           = "${var.studentname-prefix}${count.index + 1}"
  }

  provisioner "local-exec" {
    command     = <<EOH

curl -X 'POST' \
  "https://$GITEA_HOST/api/v1/admin/users" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -u $GITEA_ADMIN_USER:$GITEA_ADMIN_PASSWORD \
  -d "{
  \"email\": \"$USERNAME@$GITEA_HOST\",
  \"full_name\": \"$USERNAME\",
  \"login_name\": \"$USERNAME\",
  \"must_change_password\": false,
  \"password\": \"$PASSWORD\",
  \"send_notify\": false,
  \"source_id\": 0,
  \"username\": \"$USERNAME\",
  \"visibility\": \"public\"
}"
EOH
    interpreter = ["/bin/bash", "-c"]
    environment = {
      GITEA_HOST           = self.triggers.giteaHost
      GITEA_ADMIN_USER     = self.triggers.giteaAdminUser
      GITEA_ADMIN_PASSWORD = self.triggers.giteaAdminPassword
      USERNAME             = self.triggers.username
      PASSWORD             = self.triggers.password

    }
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<EOH
curl -X 'DELETE' \
  "https://$GITEA_HOST/api/v1/admin/users/$USERNAME" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -u $GITEA_ADMIN_USER:$GITEA_ADMIN_PASSWORD \
EOH
    interpreter = ["/bin/bash", "-c"]
    environment = {
      GITEA_HOST           = self.triggers.giteaHost
      GITEA_ADMIN_USER     = self.triggers.giteaAdminUser
      GITEA_ADMIN_PASSWORD = self.triggers.giteaAdminPassword
      USERNAME             = self.triggers.username
    }
  }

  count = var.count-students
}

resource "null_resource" "repo" {
  depends_on = [
    null_resource.giteaUser
  ]

  triggers = {
    giteaHost          = "gitea.${var.cluster_name}.${var.cluster_domain}"
    giteaAdminPassword = nonsensitive(random_password.admin-password.result)
    giteaAdminUser     = "gitea_admin"
    username           = "${var.studentname-prefix}${count.index + 1}"
  }

  provisioner "local-exec" {
    command     = <<EOH
    curl -X 'POST' \
  "https://$GITEA_HOST/api/v1/repos/migrate" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -u $GITEA_ADMIN_USER:$GITEA_ADMIN_PASSWORD \
  -d "{
  \"clone_addr\": \"https://github.com/acend/argocd-training-examples.git\",
  \"private\": false,
  \"repo_name\": \"argocd-training-examples\",
  \"repo_owner\": \"$USERNAME\"
}"
EOH
    interpreter = ["/bin/bash", "-c"]
    environment = {
      GITEA_HOST           = self.triggers.giteaHost
      GITEA_ADMIN_USER     = self.triggers.giteaAdminUser
      GITEA_ADMIN_PASSWORD = self.triggers.giteaAdminPassword
      USERNAME             = self.triggers.username
    }
  }

   provisioner "local-exec" {
     when        = destroy
     command     = <<EOH
  curl -X 'DELETE' \
   "https://$GITEA_HOST/api/v1/repos/$USERNAME/argocd-training-examples/" \
   -H 'accept: application/json' \
   -u $GITEA_ADMIN_USER:$GITEA_ADMIN_PASSWORD \
   -H 'Content-Type: application/json'
  
  EOH
     interpreter = ["/bin/bash", "-c"]
     environment = {
       GITEA_HOST           = self.triggers.giteaHost
       GITEA_ADMIN_USER     = self.triggers.giteaAdminUser
       GITEA_ADMIN_PASSWORD = self.triggers.giteaAdminPassword
       USERNAME             = self.triggers.username
     }
   }

  count = var.count-students
}
