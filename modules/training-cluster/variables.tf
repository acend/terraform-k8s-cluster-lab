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
    default = "acend-training-cluster"
}


variable "letsencrypt_email" {
    type = string
    default = "sebastian@acend.ch"
}

variable "cluster_owner_group" {
    type = string
    default = ""
}

variable "network_plugin" {
    description = "The Network Plugin to use"
    type = string
    default = "canal"
}

variable "kubernetes_version" {
    type = string
    default = "v1.20.8-rancher1-1"
}

variable "ssh_keys" {
    type = list(string)
    default = []
}

variable "rke_network_plugin" {
    description = "Mapping to know what Network Plugin (if any) Rancher should install using RKE"
    type = map
    default = {
        canal = "canal"
        cilium = "none"
    }
}