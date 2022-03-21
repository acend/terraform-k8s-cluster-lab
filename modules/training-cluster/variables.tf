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


variable "node_flavor_master" {
  description = "The cloudscale.ch VM flavor to use for the master nodes."
  type        = string
  default     = "flex-8"
}

variable "node_flavor_worker" {
  description = "The cloudscale.ch VM flavor to use for the worker nodes."
  type        = string
  default     = "flex-8"
}

variable "node_count_master" {
  description = "The number of master nodes to provision (will have roles control-plane, etcd, worker)"
  type        = number
  default     = 3
}

variable "node_count_worker" {
  description = "The number of worker nodes to provision (will have role worker)"
  type        = number
  default     = 0
}


variable "cluster_name" {
  type    = string
  default = "acend-training-cluster"
}


variable "letsencrypt_email" {
  type    = string
  default = "sebastian@acend.ch"
}

variable "acme-config" {
  type = string
}



variable "cluster_owner_group" {
  type    = string
  default = ""
}

variable "network_plugin" {
  description = "The Network Plugin to use"
  type        = string
  default     = "canal"
}

variable "kubernetes_version" {
  type    = string
  default = "v1.20.15-rancher1-1"
}

variable "ssh_keys" {
  type    = list(string)
  default = []
}

variable "rke_network_plugin" {
  description = "Mapping to know what Network Plugin (if any) Rancher should install using RKE"
  type        = map(any)
  default = {
    canal  = "canal"
    cilium = "none"
  }
}

variable "count-students" {
  type    = number
  default = 0
}

variable "studentname-prefix" {
  type    = string
  default = "user"
}

variable "argocd-enabled" {
  type    = bool
  default = false
}

variable "gitea-enabled" {
  type    = bool
  default = false
}

variable "user-vms-enabled" {
  type    = bool
  default = false
}

variable "webshell-rbac-enabled" {
  type    = bool
  default = true
}