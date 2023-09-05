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
  description = "Zone ID of the hosttech DNS Zone where LoadBalancer A/AAAA records are created"
}

variable "location" {
  type        = string
  default     = "nbg1"
  description = "Hetzner location"
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

variable "rke2_version" {
  type        = string
  default     = "v1.27.3+rke2r1"
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


variable "webshell-settings" {
  type = object({
    version                   = string
    theia-persistence-enabled = bool
    dind-persistence-enabled  = bool
    webshell-rbac-enabled     = bool
    dind_resources = object({
      limits = optional(object({
        memory = optional(string,null)
        cpu    = optional(string,null)
      }))
      requests = optional(object({
        memory = optional(string, null)
        cpu    = optional(string, null)
      }))
    })
    theia_resources = object({
      limits = optional(object({
        memory = optional(string, null)
        cpu    = optional(string, null)
      }))
      requests = optional(object({
        memory = optional(string, null)
        cpu    = optional(string, null)
      }))
    })
  })

  default = {
    version = "0.4.8"

    theia-persistence-enabled = true
    dind-persistence-enabled  = true
    webshell-rbac-enabled     = true

    dind_resources = {
      limits = {
        memory = "1Gi"
      }

      requests = {
        cpu    = "50m"
        memory = "100Mi"
      }
    }
    theia_resources = {
      requests = {
        cpu    = "750m"
        memory = "1Gi"
      }
    }
  }
}

variable "cluster_admin" {
  type        = list(any)
  default     = []
  description = "user with cluster-admin permissions"
}

variable "first_install" {
  type        = bool
  default     = true
  description = "Indicate if this is the very first installation. RKE2 needs to handle the first controlplane node special when its the initial installation"
}