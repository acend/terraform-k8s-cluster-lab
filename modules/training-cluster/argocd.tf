
resource "kubernetes_namespace" "argocd" {

  provider = kubernetes.local

  depends_on = [
    null_resource.wait_for_k8s_api
  ]

  metadata {
    name = "argocd"

    labels = {
      certificate-wildcard          = "true"
      "kubernetes.io/metadata.name" = "argocd"
    }
  }
}

resource "random_password" "argocd-admin-password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "helm_release" "argocd" {

  name        = "argocd"
  repository  = "https://argoproj.github.io/argo-helm"
  chart       = "argo-cd"
  namespace   = kubernetes_namespace.argocd.metadata.0.name
  version     = "7.3.4"
  wait        = true
  max_history = 2

  set {
    name  = "global.domain"
    value = "argocd.${var.cluster_name}.${var.cluster_domain}"
  }

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = random_password.argocd-admin-password.bcrypt_hash
  }

  set {
    name  = "server.ingress.hostname"
    value = "argocd.${var.cluster_name}.${var.cluster_domain}"
  }

  set {
    name  = "server.ingress.extraTls[0].hosts[0]"
    value = "argocd.${var.cluster_name}.${var.cluster_domain}"
  }

  set {
    name  = "server.ingressGrpc.hostname"
    value = "argocd-grpc.${var.cluster_name}.${var.cluster_domain}"
  }

  set {
    name  = "server.ingressGrpc.extraTls[0].hosts[0]"
    value = "argocd-grpc.${var.cluster_name}.${var.cluster_domain}"
  }

  values = [
    templatefile("${path.module}/manifests/argocd/values_account_student.yaml", { studentname-prefix = var.studentname-prefix, count-students = var.count-students, passwords = random_password.student-passwords }),
    templatefile("${path.module}/manifests/argocd/values_rbacConfig_policy.yaml", { studentname-prefix = var.studentname-prefix, count-students = var.count-students, cluster_admin = var.cluster_admin }),
    templatefile("${path.module}/manifests/argocd/values.yaml", { cluster_name = var.cluster_name, cluster_domain = var.cluster_domain }),
  ]

}

resource "null_resource" "cleanup-before-destroy" {

  depends_on = [
    time_sleep.wait_for_argocd-cleanup,
    kubernetes_secret.argocd-cluster
    ]


  triggers = {
    kubeconfig = base64encode(local.kubeconfig_raw)

  }
  provisioner "local-exec" {
    when        = destroy
    command     = <<EOH
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
chmod +x ./kubectl
./kubectl -n argocd delete application bootstrap --kubeconfig <(echo $KUBECONFIG | base64 --decode) || true
./kubectl -n argocd delete application --all --kubeconfig <(echo $KUBECONFIG | base64 --decode) || true
./kubectl -n argocd delete applicationsets --all --kubeconfig <(echo $KUBECONFIG | base64 --decode) || true
./kubectl delete ns ingress-haproxy --kubeconfig <(echo $KUBECONFIG | base64 --decode) || true
EOH
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}


resource "time_sleep" "wait_for_argocd-cleanup" {

  depends_on = [
    helm_release.argocd
  ]

  destroy_duration = "180s"
}