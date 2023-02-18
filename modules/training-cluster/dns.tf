resource "restapi_object" "labapp-a-record" {
  provider     = restapi.hosttech_dns
  path         = "/api/user/v1/zones/${var.hosttech-dns-zone-id}/records"
  data         = "{\"type\": \"A\",\"name\": \"*.labapp\",\"ipv4\": \"${replace(cloudscale_floating_ip.vip-v4.network, "/32", "")}\",\"ttl\": 3600,\"comment\": \"Labapp Wildcard\"}"
  id_attribute = "data/id"
}

resource "restapi_object" "labapp-aaaa-record" {
  provider     = restapi.hosttech_dns
  path         = "/api/user/v1/zones/${var.hosttech-dns-zone-id}/records"
  data         = "{\"type\": \"AAAA\",\"name\": \"*.labapp\",\"ipv6\": \"${replace(cloudscale_floating_ip.vip-v6.network, "/128", "")}\",\"ttl\": 3600,\"comment\": \"Labapp Wildcard\"}"
  id_attribute = "data/id"
}