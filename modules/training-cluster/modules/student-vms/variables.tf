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

variable "location" {
  type        = string
  default     = "nbg1"
  description = "hetzner location"
}
variable "ssh_key" {
  type    = string
}

variable "cluster_name" {
  type        = string
  description = "name of the cluster"
}