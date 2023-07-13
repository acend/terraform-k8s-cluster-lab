module "api-a-record" {

  providers = {
    restapi = restapi.hosttech_dns
  }

  source = "./modules/hosttech-dns-record"

  hosttech-dns-zone-id = var.hosttech-dns-zone-id

  type    = "A"
  name    = "api.${var.cluster_name}.${split(".", var.cluster_domain)[0]}"
  ipv4    = hcloud_load_balancer.lb.ipv4
  comment = "K8S API for Training Cluster ${var.cluster_name}"
  ttl     = 3600
}

module "api-aaaa-record" {

  providers = {
    restapi = restapi.hosttech_dns
  }

  source = "./modules/hosttech-dns-record"

  hosttech-dns-zone-id = var.hosttech-dns-zone-id

  type    = "AAAA"
  name    = "api.${var.cluster_name}.${split(".", var.cluster_domain)[0]}"
  ipv6    = hcloud_load_balancer.lb.ipv6
  comment = "K8S API for Training Cluster ${var.cluster_name}"
  ttl     = 3600
}