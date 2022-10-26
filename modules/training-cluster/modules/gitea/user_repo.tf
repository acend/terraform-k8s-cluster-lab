# resource "null_resource" "getGiteaToken" {

#   triggers = {
#     kubeconfig = base64encode(nonsensitive(var.kubeconfig))
#     giteaHost = "gitea.${var.domain}"
#     giteaAdminPassword = nonsensitive(random_password.admin-password.result)
#     giteaAdminUser = "gitea_admin"
#     always_run = "${timestamp()}"
#   }

#   provisioner "local-exec" {
#     command = <<EOH
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
# echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
# chmod +x ./kubectl

# curl -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
# chmod 0755 jq


# ./kubectl -n gitea wait --for=condition=Ready Pods -l app=gitea --timeout=90s --kubeconfig <(echo $KUBECONFIG | base64 --decode)

# token_result=$(curl -XPOST -H "Content-Type: application/json"  -k -d '{"name":"admin-token-'$TIMESTAMP'"}' -s -u $GITEA_ADMIN_USER:$GITEA_ADMIN_PASSWORD https://$GITEA_HOST/api/v1/users/$GITEA_ADMIN_USER/tokens)
# echo $token_result > ${path.module}/gitea_token_raw
# echo $token_result | ./jq '.sha1' | sed 's/\"//g' > ${path.module}/gitea_token
# cat ${path.module}/gitea_token_raw
# cat ${path.module}/gitea_token


# EOH
#     interpreter = ["/bin/bash", "-c"]
# environment = {
#       KUBECONFIG = self.triggers.kubeconfig
#       GITEA_HOST = self.triggers.giteaHost
#       GITEA_ADMIN_USER = self.triggers.giteaAdminUser
#       GITEA_ADMIN_PASSWORD = self.triggers.giteaAdminPassword
#       TIMESTAMP = self.triggers.always_run
#   }
#  }



#  depends_on = [
#    helm_release.gitea
#  ]
# }

# data "local_file" "giteaToken" {
#   filename = "${path.module}/gitea_token"

#   depends_on = [
#     null_resource.getGiteaToken
#   ]
# }

# data "local_file" "giteaToken_raw" {
#   filename = "${path.module}/gitea_token_raw"

#   depends_on = [
#     null_resource.getGiteaToken
#   ]
# }

resource "null_resource" "giteaUser" {

  triggers = {
    giteaHost = "gitea.${var.domain}"
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
      GITEA_HOST = self.triggers.giteaHost
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
      GITEA_HOST = self.triggers.giteaHost
      GITEA_ADMIN_USER     = self.triggers.giteaAdminUser
      GITEA_ADMIN_PASSWORD = self.triggers.giteaAdminPassword
      USERNAME             = self.triggers.username
    }
  }

  count = var.count-students
}

resource "null_resource" "repo" {

  triggers = {
    giteaHost          = "gitea.${var.domain}"
    giteaAdminPassword = nonsensitive(random_password.admin-password.result)
    giteaAdminUser     = "gitea_admin"
    username = "${var.studentname-prefix}${count.index + 1}"
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
      GITEA_HOST = self.triggers.giteaHost
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
      GITEA_HOST = self.triggers.giteaHost
      GITEA_ADMIN_USER     = self.triggers.giteaAdminUser
      GITEA_ADMIN_PASSWORD = self.triggers.giteaAdminPassword
      USERNAME             = self.triggers.username
    }
  }

  depends_on = [
    null_resource.giteaUser
  ]

  count = var.count-students
}