variable "chart-repository" {
  type    = string
  default = "https://dl.gitea.io/charts/"
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