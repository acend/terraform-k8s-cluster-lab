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

variable "cluster_owner_group" {
    type = string
    default = ""
}

variable "network_plugin" {
    description = "The Network Plugin Rancher should install on the Cluster"
    type = string
    default = "canal"
}

variable "ssh_keys" {
    type = list(string)
    default = []
}