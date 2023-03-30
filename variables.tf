variable "hcloud_api_token" {
  type      = string
  sensitive = true
}

variable "hosttech_dns_token" {
  type        = string
  description = "hosttech dns api token"
}

variable "hosttech-dns-zone-id" {
  type        = string
  description = "Zone ID of the hosttech DNS Zone where LoadBalancer A/AAAA records are created"
}

variable "cluster_name" {
  type    = string
  default = "acend-training-cluster"
}


variable "worker_count" {
  default     = 2
  description = "Count of rke2 workers"
}

variable "extra_ssh_keys" {
  type        = list(any)
  default     = []
  description = "Extra ssh keys to inject into vm's"
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

variable "cluster_admin" {
  type        = list
  default     = []
  description = "user with cluster-admin permissions"
}