variable "rancher_training_project" {
}


variable "chart-repository" {
    default = "https://github.com/acend/webshell-env/raw/helm-chart/deploy/charts/webshell-0.1.0.tgz"
}
variable "student-name" {

}

variable "domain" {
    default = "labapp.acend.ch"
}