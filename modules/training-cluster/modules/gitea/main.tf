
resource "rancher2_namespace" "gitea-namespace" {

  name       = "gitea"
  project_id = var.rancher_system_project.id

  labels = {
    certificate-labapp = "true"
    "kubernetes.io/metadata.name" = "gitea"
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
  namespace  = rancher2_namespace.gitea-namespace.name

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
    value = "gitea.${var.domain}"
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
    value = "gitea.${var.domain}"
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "labapp-wildcard"
  }

}

resource "null_resource" "getGiteaToken" {

  triggers = {
    kubeconfig = base64encode(var.kubeconfig)
    giteaHost = "gitea.${var.domain}"
    giteaAdminPassword = random_password.admin-password.result
    giteaAdminUser = "gitea_admin"
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<EOH
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
chmod +x ./kubectl

curl -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod 0755 jq


./kubectl -n gitea wait --for=condition=Ready Pods -l app=gitea --timeout=90s --kubeconfig <(echo $KUBECONFIG | base64 --decode)

token_result=$(curl -XPOST -H "Content-Type: application/json"  -k -d '{"name":"admin-token"}' -s -u $GITEA_ADMIN_USER:$GITEA_ADMIN_PASSWORD https://$GITEA_HOST/api/v1/users/$GITEA_ADMIN_USER/tokens)
echo $token_result | ./jq '.sha1' | sed 's/\"//g' > ${path.module}/gitea_token


EOH
    interpreter = ["/bin/bash", "-c"]
environment = {
      KUBECONFIG = self.triggers.kubeconfig
      GITEA_HOST = self.triggers.giteaHost
      GITEA_ADMIN_USER = self.triggers.giteaAdminUser
      GITEA_ADMIN_PASSWORD = self.triggers.giteaAdminPassword
  }
 }



 depends_on = [
   helm_release.gitea
 ]
}

data "local_file" "giteaToken" {
  filename = "${path.module}/gitea_token"

  depends_on = [
    null_resource.getGiteaToken
  ]
}


resource "null_resource" "giteaUser" {

  triggers = {
    kubeconfig = base64encode(var.kubeconfig)
    giteaHost = "gitea.${var.domain}"
    giteaToken = random_password.admin-password.result
    username = "${var.studentname-prefix}${count.index + 1}"
  }

  provisioner "local-exec" {
    command = <<EOH

curl -X 'POST' \
  "https://$GITEA_HOST/api/v1/admin/users" \
  -H 'accept: application/json' \
  -H "Authorization: token $GITEA_TOKEN" \
  -H 'Content-Type: application/json' \
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
        KUBECONFIG = self.triggers.kubeconfig
        GITEA_HOST = self.triggers.giteaHost
        GITEA_TOKEN = self.triggers.giteaToken
        USERNAME = self.triggers.username
        PASSWORD = self.triggers.password

    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOH
curl -X 'DELETE' \
  "https://$GITEA_HOST/api/v1/admin/users/$USERNAME" \
  -H 'accept: application/json' \
  -H "Authorization: token $GITEA_TOKEN" \
  -H 'Content-Type: application/json' \
}"
EOH
    interpreter = ["/bin/bash", "-c"]
    environment = {
        KUBECONFIG = self.triggers.kubeconfig
        GITEA_HOST = self.triggers.giteaHost
        GITEA_TOKEN = self.triggers.giteaToken
        USERNAME = self.triggers.username
    }
  }

  count = var.count-students
 }

 resource "null_resource" "repo" {

  triggers = {
    kubeconfig = base64encode(var.kubeconfig)
    giteaHost = "gitea.${var.domain}"
    giteaToken = random_password.admin-password.result
    username = "${var.studentname-prefix}${count.index + 1}"
  }

  provisioner "local-exec" {
    command = <<EOH

    curl -X 'POST' \
  "https://$GITEA_HOST/api/v1/repos/migrate" \
  -H 'accept: application/json' \
  -H "Authorization: token $GITEA_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"clone_addr\": \"https://github.com/acend/argocd-training-examples.git\",
  \"private\": false,
  \"repo_name\": \"argocd-training-examples\",
  \"repo_owner\": \"$USERNAME\"
}"
EOH
    interpreter = ["/bin/bash", "-c"]
    environment = {
        KUBECONFIG = self.triggers.kubeconfig
        GITEA_HOST = self.triggers.giteaHost
        GITEA_TOKEN = self.triggers.giteaToken
        USERNAME = self.triggers.username
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOH
curl -X 'DELETE' \
  "https://$GITEA_HOST/api/v1/repos/$USERNAME/argocd-training-examples/" \
  -H 'accept: application/json' \
  -H "Authorization: token $GITEA_TOKEN" \
  -H 'Content-Type: application/json' \

EOH
    interpreter = ["/bin/bash", "-c"]
    environment = {
        KUBECONFIG = self.triggers.kubeconfig
        GITEA_HOST = self.triggers.giteaHost
        GITEA_TOKEN = self.triggers.giteaToken
        USERNAME = self.triggers.username
    }
  }

  count = var.count-students
 }