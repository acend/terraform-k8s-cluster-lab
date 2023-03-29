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

variable "location" {
  type        = string
  default     = "nbg1"
  description = "hetzner location"
}

variable "cluster_name" {
  type        = string
  description = "name of the cluster"
}

variable "cluster_domain" {
  type        = string
  description = "common subdomain for all cluster"
  default     = "labcluster.acend.ch"
}
variable "rke2_version" {
  type        = string
  default     = "v1.26.2+rke2r1"
  description = "Version of rke2 to install"
}

variable "network" {
  type        = string
  default     = "10.0.0.0/8"
  description = "network to use"
}
variable "subnetwork" {
  type        = string
  default     = "10.0.0.0/24"
  description = "subnetwork to use"
}
variable "networkzone" {
  type        = string
  default     = "eu-central"
  description = "hetzner netzwork zone"
}

variable "internalbalancerip" {
  type        = string
  default     = "10.0.0.2"
  description = "IP to use for control plane loadbalancer"
}
variable "lb_type" {
  type        = string
  default     = "lb11"
  description = "Load balancer type"
}


variable "controlplane_type" {
  type        = string
  default     = "cpx31"
  description = "machine type to use for the controlplanes"
}

variable "worker_type" {
  type        = string
  default     = "cpx41"
  description = "machine type to use for the controlplanes"
}

variable "node_image_type" {
  type        = string
  default     = "ubuntu-22.04"
  description = "Image Type for all Nodes"
}

variable "controlplane_count" {
  default     = 3
  description = "Count of rke2 servers"

  validation {
    condition     = var.controlplane_count == 3
    error_message = "You must have 3 master nodes."
  }
}

variable "worker_count" {
  default     = 2
  description = "Count of rke2 workers"
}

variable "letsencrypt_email" {
  type    = string
  default = "sebastian@acend.ch"
}


variable "extra_ssh_keys" {
  type        = list(any)
  default     = []
  description = "Extra ssh keys to inject into vm's"
}
variable "k8s-cluster-cidr" {
  default = "10.244.0.0/16"
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

variable "first_install" {
  type = bool
  default = false
  description = "Indicate if this is the very first installation. RKE2 needs to handle the first controlplane node special when its the initial installation"
}

variable "cluster_admin" {
  type        = list
  default     = []
  description = "user with cluster-admin permissions"
}