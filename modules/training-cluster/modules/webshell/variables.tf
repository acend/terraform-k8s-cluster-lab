variable "chart-repository" {
  type    = string
  default = "https://acend.github.io/webshell-env/"
}

variable "chart-version" {
  type    = string
  default = "0.3.2"
}

variable "student-index" {

}
variable "student-name" {
  type = string
}

variable "student-password" {
  type = string
}

variable "user-vm-enabled" {
  type = bool
}

variable "student-vms" {
}

variable "rbac-enabled" {
  type    = bool
  default = true
}

variable "dind-persistence-enabled" {
  type    = bool
  default = true
}

variable "theia-persistence-enabled" {
  type    = bool
  default = true
}

variable "cluster_name" {
  type        = string
  description = "name of the cluster"
}

variable "cluster_domain" {
  type        = string
  description = "common subdomain for cluster"
}