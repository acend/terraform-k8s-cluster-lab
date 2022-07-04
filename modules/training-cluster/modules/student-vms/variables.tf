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

variable "vm-flavor" {
  type    = string
  default = "flex-8"
}

variable "ssh_keys" {
  type    = list(string)
  default = []
}

