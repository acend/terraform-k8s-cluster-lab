variable "rancher_training_project" {
}

variable "rancher_system_project" {
}

variable "chart-repository" {
  type    = string
  default = "https://argoproj.github.io/argo-helm"
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