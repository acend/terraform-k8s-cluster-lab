resource "kubernetes_config_map" "welcome-content" {

  depends_on = [
    time_sleep.wait_for_cluster_ready,
  ]

  metadata {
    name      = "welcome-content"
    namespace = "default"
  }

  data = {
    "index.html" = "${templatefile("${path.module}/manifests/welcome.html", {
      count_students     = var.count-students,
      passwords          = random_password.student-passwords
      studentname-prefix = var.studentname-prefix
      appdomain          = "${var.cluster_name}.${var.cluster_domain}",
      cluster_domain     = var.cluster_domain,
      cluster_name       = var.cluster_name,
    })}"
  }
}

resource "kubernetes_service" "welcome" {
  metadata {
    name      = "welcome"
    namespace = "default"
  }
  spec {
    selector = {
      app = "welcome"
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "welcome" {
  metadata {
    name = "welcome"
    labels = {
      app = "welcome"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "welcome"
      }
    }

    template {
      metadata {
        labels = {
          app = "welcome"
        }
      }

      spec {
        container {
          image = "nginxinc/nginx-unprivileged:latest"
          name  = "welcome"

          readiness_probe {
            http_get {
              path = "/"
              port = 8080

            }
          }

          volume_mount {
            name       = "content"
            mount_path = "/usr/share/nginx/html"
          }
        }

        volume {
          name = "content"

          config_map {
            name = kubernetes_config_map.welcome-content.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "welcome" {
  metadata {
    name      = "welcome"
    namespace = "default"
  }

  spec {


    rule {
      host = "welcome.${var.cluster_name}.${var.cluster_domain}"

      http {
        path {
          backend {
            service {
              name = "welcome"
              port {
                number = 80
              }
            }
          }

          path = "/"
        }


      }
    }

    tls {
      hosts = [
        "welcome.${var.cluster_name}.${var.cluster_domain}"
      ]
    }
  }
}