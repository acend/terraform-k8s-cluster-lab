variable "hcloud_api_token" {
  type        = string
  sensitive   = true
  description = "Hetzner Cloud API Token"
}

variable "hosttech_dns_token" {
  type        = string
  description = "Hosttech DNS Api Token"
}

variable "hosttech-dns-zone-id" {
  type        = string
  description = "Zone ID of the Hosttech DNS Zone where LoadBalancer A/AAAA records are created"
}

variable "cluster_name" {
  type        = string
  default     = "training"
  description = "The name for the cluster to be created. This is used also used in the DNS Name, or VM Hostname"

  validation {
    condition     = can(regex("^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$", var.cluster_name))
    error_message = "cluster_name must be a valid hostname"
  }
}

variable "cluster_domain" {
  type        = string
  description = "common subdomain for all cluster"
  default     = "cluster.acend.ch"
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

variable "dind-persistence-enabled" {
  description = "Enable persistence for DinD container"
  type        = bool
  default     = true
}

variable "theia-persistence-enabled" {
  description = "Enable persistence for theia container"
  type        = bool
  default     = true
}


variable "cluster_admin" {
  type        = list(any)
  default     = []
  description = "user with cluster-admin permissions"
}