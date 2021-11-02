variable "rancher_training_project" {
}

variable "chart-repository" {
    type = string
    default = "https://argoproj.github.io/argo-helm"
}


variable "count-students" {
  type        = number
  default     = 0
}