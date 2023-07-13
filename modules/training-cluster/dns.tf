resource "restapi_object" "api-a-record" {
  provider     = restapi.hosttech_dns
  path         = "/api/user/v1/zones/${var.hosttech-dns-zone-id}/records"
  data         = "{\"type\": \"A\",\"name\": \"api.${var.cluster_name}.${split(".", var.cluster_domain)[0]}\",\"ipv4\": \"${hcloud_load_balancer.lb.ipv4}\",\"ttl\": 3600,\"comment\": \"K8S API for Lab Cluster ${var.cluster_name}\"}"
  id_attribute = "data/id"
}

resource "restapi_object" "api-aaaa-record" {
  provider     = restapi.hosttech_dns
  path         = "/api/user/v1/zones/${var.hosttech-dns-zone-id}/records"
  data         = "{\"type\": \"AAAA\",\"name\": \"api.${var.cluster_name}.${split(".", var.cluster_domain)[0]}\",\"ipv6\": \"${hcloud_load_balancer.lb.ipv6}\",\"ttl\": 3600,\"comment\": \"K8S API Lab Cluster ${var.cluster_name}\"}"
  id_attribute = "data/id"
}


module "ingress-a-record" {

  providers = {
    restapi = restapi.hosttech_dns
  }

  source = "./modules/hosttech-dns-record"

  hosttech-dns-zone-id = var.hosttech-dns-zone-id

  type    = "A"
  name    = "*.${var.cluster_name}.${split(".", var.cluster_domain)[0]}"
  ipv4    = data.kubernetes_service.ingress-haproxy.status.0.load_balancer.0.ingress.0.ip
  comment = "Ingress Wildcard for Lab Cluster ${var.cluster_name}"



}
module "ingress-aaaa-record" {
  providers = {
    restapi = restapi.hosttech_dns
  }
  source = "./modules/hosttech-dns-record"

  hosttech-dns-zone-id = var.hosttech-dns-zone-id

  type    = "AAAA"
  name    = "*.${var.cluster_name}.${split(".", var.cluster_domain)[0]}"
  ipv6    = data.kubernetes_service.ingress-haproxy.status.0.load_balancer.0.ingress.1.ip
  comment = "Ingress Wildcard for Lab Cluster ${var.cluster_name}"

}
