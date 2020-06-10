variable "rancher2_access_key" {
    type = string
}

variable "rancher2_secret_key" {
    type = string
}

variable "cloudscale_token" {
    type = string
}

variable "rancher2_api_url" {
    type = string
}


variable "cluster_name" {
    type = string
    default = "techlab"
}

variable "node_template_name" {
    type = string
    default = "acend GmbH - flex-8 - 50 GB Root"
}

variable "letsencrypt_email" {
    type = string
    default = "sebastian@acend.ch"
}