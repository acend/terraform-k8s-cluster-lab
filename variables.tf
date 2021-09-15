variable "rancher2_access_key" {
  type = string
}

variable "rancher2_secret_key" {
  type      = string
  sensitive = true
}

variable "cloudscale_token" {
  type      = string
  sensitive = true
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

variable "cluster_owner_group" {
  description = "The group_principal_id of a Rancher group which will become cluster owner"
  type        = string
  default     = ""
}

variable "network_plugin" {
  description = "The Network Plugin Rancher should install on the Cluster"
  type        = string
  default     = "canal"
}

variable "ssh_keys" {
  description = "SSH Public keys with access to the cloudscale.ch VM's"
  type        = list(string)
  default     = []
}