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

variable "cluster_name" {
  type    = string
  default = "acend-training-cluster"
}

variable "domain" {
  default = "labapp.acend.ch"
}

variable "node_flavor_master" {
  description = "The cloudscale.ch VM flavor to use for the master nodes."
  type        = string
  default     = "flex-8-2"
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


variable "ssh_keys" {
  description = "SSH Public keys with access to the cloudscale.ch VM's"
  type        = list(string)
  default     = []
}

variable "acme-config" {
  type = string
}

variable "count-students" {
  description = "Number of students"
  type        = number
  default     = 0
}

variable "argocd-enabled" {
  description = "Switch to deploy argocd instance and configure it for the students"
  type        = bool
  default     = false
}

variable "gitea-enabled" {
  description = "Switch to deploy Gitea"
  type        = bool
  default     = false
}

variable "user-vms-enabled" {
  description = "Deploy a VM for each User"
  type        = bool
  default     = false
}

variable "webshell-rbac-enabled" {
  description = "Deploy RBAC to access Kubernetes Cluster for each student"
  type        = bool
  default     = true
}