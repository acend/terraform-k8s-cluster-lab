variable "rancher_system_project" {
}

variable "chart_version" {
  type    = string
  default = "v1.5.3"
}

variable "letsencrypt_email" {
  type    = string
  default = "info@acend.ch"
}

variable "acme-config" {
  type = string
}

