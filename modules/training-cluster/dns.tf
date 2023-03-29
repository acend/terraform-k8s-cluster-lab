resource "restapi_object" "api-a-record" {
  provider     = restapi.hosttech_dns
  path         = "/api/user/v1/zones/${var.hosttech-dns-zone-id}/records"
  data         = "{\"type\": \"A\",\"name\": \"api.${var.cluster_name}.labcluster\",\"ipv4\": \"${hcloud_load_balancer.lb.ipv4}\",\"ttl\": 3600,\"comment\": \"K8S API for Lab Cluster ${var.cluster_name}\"}"
  id_attribute = "data/id"
}

resource "restapi_object" "api-aaaa-record" {
  provider     = restapi.hosttech_dns
  path         = "/api/user/v1/zones/${var.hosttech-dns-zone-id}/records"
  data         = "{\"type\": \"AAAA\",\"name\": \"api.${var.cluster_name}.labcluster\",\"ipv6\": \"${hcloud_load_balancer.lb.ipv6}\",\"ttl\": 3600,\"comment\": \"K8S API Lab Cluster ${var.cluster_name}\"}"
  id_attribute = "data/id"
}


resource "restapi_object" "labapp-a-record" {
  provider     = restapi.hosttech_dns
  path         = "/api/user/v1/zones/${var.hosttech-dns-zone-id}/records"
  data         = "{\"type\": \"A\",\"name\": \"*.${var.cluster_name}.labcluster\",\"ipv4\": \"${data.kubernetes_service.ingress-nginx.status.0.load_balancer.0.ingress.0.ip}\",\"ttl\": 3600,\"comment\": \"Ingress Wildcard for Lab Cluster ${var.cluster_name}\"}"
  id_attribute = "data/id"
}

resource "restapi_object" "labapp-aaaa-record" {
  provider     = restapi.hosttech_dns
  path         = "/api/user/v1/zones/${var.hosttech-dns-zone-id}/records"
  data         = "{\"type\": \"AAAA\",\"name\": \"*.${var.cluster_name}.labcluster\",\"ipv6\": \"${data.kubernetes_service.ingress-nginx.status.0.load_balancer.0.ingress.1.ip}\",\"ttl\": 3600,\"comment\": \"Ingress Wildcard for Lab Cluster ${var.cluster_name}\"}"
  id_attribute = "data/id"
}