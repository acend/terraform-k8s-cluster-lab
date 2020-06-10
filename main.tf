variable "rancher2_access_key" {
    type = string
}

variable "rancher2_secret_key" {
    type = string
}

variable "cloudscale_token" {
    type = string
}

variable "rancher2_api_url" {
    type = string
}



module "techlab-cluster" {
  source = "./modules/techlab-cluster"

  rancher2_access_key = var.rancher2_access_key
  rancher2_secret_key = var.rancher2_secret_key
  rancher2_api_url = var.rancher2_api_url
  cloudscale_token = var.cloudscale_token

}
