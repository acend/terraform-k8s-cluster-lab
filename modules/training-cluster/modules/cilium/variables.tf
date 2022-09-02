variable "rancher_system_project" {
}

variable "chart_version" {
  type    = string
  default = "1.12.1"
}

variable "public_ip" {
  type    = string
  default = ""
}


variable "hubble-ui-ingress-enabled" {
  type    = bool
  default = false
}
