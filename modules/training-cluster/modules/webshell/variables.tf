variable "rancher_training_project" {
}

variable "rancher_quotalab_project" {
}



variable "chart-repository" {
  type    = string
  default = "https://acend.github.io/webshell-env/"
}

variable "chart-version" {
  type    = string
  default = "0.2.6"
}

variable "student-index" {

}
variable "student-name" {
  type = string
}

variable "student-password" {
  type = string
}

variable "domain" {
  default = "labapp.acend.ch"
}

variable user-vm-enabled {
  type = bool
}

variable student-vms {
}

variable rbac-enabled {
  type = bool
  default = true
}