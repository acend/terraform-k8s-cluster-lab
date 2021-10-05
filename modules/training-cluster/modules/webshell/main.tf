

resource "rancher2_namespace" "student-namespace" {

  name       = var.student-name
  project_id = var.rancher_training_project.id

  labels {
      certificate-labapp = "true"
  }
}

resource "kubernetes_role_binding" "admin-rb" {
  metadata {
    name      = "${var.student-name}-rb"
    namespace = var.student-name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = var.student-name
  }
}

resource "kubernetes_cluster_role_binding" "view-crb" {
  metadata {
    name = "${var.student-name}-crb"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = var.student-name
  }
}

resource "kubernetes_service" "theia-svc" {
  metadata {
    name = "${var.student-name}-theia-svc"
    namespace = var.student-name
    labels = {
      app = "theia"
    }
  }
  spec {
    selector = {
      app = "theia"
    }

    port {
      port        = 3000
      target_port = 3000
      name        = "web"
      protocol    = "TCP"
    }

  }
}

resource "kubernetes_deployment" "theia" {
  metadata {
    name = "${var.student-name}-theia-deploy"
    namespace = var.student-name
    labels = {
      app = "theia"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "theia"
      }
    }

    template {
      metadata {
        labels = {
          app = "theia"
        }
      }

      spec {

        init_container {
          image = "busybox"
          name  = "welcome-msg"

          volume_mount {
            name = shared-data
            mount_path = "/home/project"
          }

          command = ["sh", "-c", "echo Welcome to the acend theia ide > /home/project/welcome"]


        } # init-container

        container {
          image = "quay.io/acend/theia:latest"
          name  = "theia"

          resources {
            limits = {
              cpu    = "500m"
              memory = "500Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "50Mi"
            }
          }

          env {
            name = student
            value = var.student-name
          }

          port {
              container_port = 3000
              protocol       = TCP
          }

          volume_mount {
            name = shared-data
            mount_path = "/home/project"
          }

        } # thei container

        container {
          image = "docker:18.09.9-dind"
          name  = "dind"

          tty   = true
          stdin = true

          port {
            container_port = 2375
            protocol       = TCP
          }

          liveness_probe {
            tcpSocket {
                port = 2375
            }

            initial_delay_seconds = 5
            timeout_seconds = 10
          }

          readiness_probe {
            tcpSocket {
                port = 2375
            }

            initial_delay_seconds = 2
            timeout_seconds = 10
          }

          security_context {
            allow_privilege_escalation = true
            privileged = true
            run_as_non_root = false
            read_only_root_filesystem = false

          }

          volume_mount {
            name = shared-data
            mount_path = "/home/project"
          }
        } # dind container

        volume {
            empty_dir {

            }

            name = "shared_data"
        }


      }
    }
  }
}

resource "kubernetes_resource_quota" "example" {
  metadata {
    name = "theia-rq"
    namespace = var.student-name
  }
  spec {
    hard = {
      pods = 15
    }
  }
}

esource "kubernetes_ingress" "theia" {
  metadata {
    name = "theia-ing"
    namespace = var.student-name

    annotations = {
        kubernetes.io/ingress.class: "nginx"
        ingress.kubernetes.io/ssl-redirect: "true"
        nginx.ingress.kubernetes.io/auth-type: basic
        nginx.ingress.kubernetes.io/auth-secret: basic-auth
    }
  }

  spec {
    backend {
      service_name = "${var.student-name}-theia-svc"
      service_port = 3000
    }

    rule {
      host = "$(var.student-name).${var.domain}"
      http {
        path {
          backend {
            service_name = "${var.student-name}-theia-svc"
            service_port = 3000
          }

          path = "/"
        }


      }
    }

    tls {
      secret_name = "labapp-wildcard"

      hosts = ["$(var.student-name).${var.domain}"]
    }
  }
}