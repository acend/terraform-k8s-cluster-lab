variable "rancher_training_project" {
}

variable "rancher_quotalab_project" {
}



variable "chart-repository" {
    type = string
    default = "https://github.com/acend/webshell-env/raw/main/deploy/charts/webshell-0.1.0.tgz"
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