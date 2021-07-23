

module "training-cluster" {
  source = "./modules/training-cluster"

  rancher2_access_key = var.rancher2_access_key
  rancher2_secret_key = var.rancher2_secret_key
  rancher2_api_url = var.rancher2_api_url
  cloudscale_token = var.cloudscale_token
  cluster_owner_group = var.cluster_owner_group
  network_plugin = var.network_plugin
  ssh_keys = var.ssh_keys

}
