variable "hosttech-dns-zone-id" {
  type = string
}

variable "type" {
  type    = string
  default = "A"

  validation {
    condition     = var.type == "A" || var.type == "AAAA"
    error_message = "The record type must be A or AAAA"
  }
}

variable "name" {
  type = string
}

variable "ttl" {
  type    = "number"
  default = 3600
}

variable "commment" {
  type = string
}

variable "ipv4" {
  type = string
}

variable "ipv6" {
  type = string
}



resource "restapi_object" "a-record" {
  provider = restapi.hosttech_dns
  path     = "/api/user/v1/zones/${var.hosttech-dns-zone-id}/records"

  data = (jsonencode({
    type    = var.type
    name    = var.name
    ipv4    = var.ipv4
    ttl     = var.ttl
    comment = var.comment
  }))

  id_attribute = "data/id"

  count = var.type == "A" ? 1 : 0
}

resource "restapi_object" "aaaa-record" {
  provider = restapi.hosttech_dns
  path     = "/api/user/v1/zones/${var.hosttech-dns-zone-id}/records"

  data = jsonencode({
    type    = var.type
    name    = var.name
    ipv6    = var.ipv6
    ttl     = var.ttl
    comment = var.comment
  })

  id_attribute = "data/id"

  count = var.type == "AAAA" ? 1 : 0
}