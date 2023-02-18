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

variable "hosttech_dns_token" {
  type        = string
  description = "hosttech dns api token"
}

variable "hosttech-dns-zone-id" {
  type        = string
  description = "Zone ID of the hosttech DNS Zone where LoadBalancer A/AAAA records are created"
}

variable "node_flavor_master" {
  description = "The cloudscale.ch VM flavor to use for the master nodes."
  type        = string
  default     = "flex-8-4"
}

variable "node_flavor_worker" {
  description = "The cloudscale.ch VM flavor to use for the worker nodes."
  type        = string
  default     = "flex-8-4"
}

variable "node_count_master" {
  description = "The number of master nodes to provision (will have roles control-plane, etcd, worker)"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count_master == 3
    error_message = "You must have 3 master nodes."
  }
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

variable "cluster_owner_group" {
  type    = string
  default = ""
}


variable "kubernetes_version" {
  type    = string
  default = "v1.24.4+rke2r1"
}

variable "ssh_keys" {
  type    = list(string)
  default = []
}

variable "domain" {
  default = "labapp.acend.ch"
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