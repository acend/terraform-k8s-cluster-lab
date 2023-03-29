variable "chart-repository" {
  type    = string
  default = "https://argoproj.github.io/argo-helm"
}

variable "chart-version" {
  type    = string
  default = "5.24.1"
}

variable "cluster_name" {
  type        = string
  description = "name of the cluster"
}

variable "cluster_domain" {
  type        = string
  description = "common subdomain for cluster"
}

variable "count-students" {
  type    = number
  default = 0
}

variable "student-passwords" {
  type = list(any)
}

variable "studentname-prefix" {
  type    = string
  default = "student"
}

variable "kubeconfig_raw" {
  type = string
  
}