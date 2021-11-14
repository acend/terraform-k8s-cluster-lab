variable "rancher_training_project" {
}

variable "rancher_quotalab_project" {
}



variable "chart-repository" {
    type = string
    default = "https://acend.github.io/webshell-env/"
}

variable "chart-version" {
    type = string
    default = "0.1.7"
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