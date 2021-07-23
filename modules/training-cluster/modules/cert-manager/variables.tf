variable "project_id" {
    type = string
}

variable "chart_version" {
    type = string
    default = "v1.4.1"
}

variable "letsencrypt_email" {
    type = string
    default = "info@acend.ch"
}