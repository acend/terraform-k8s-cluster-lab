
terraform {
	backend "remote" {}
}

module "training-cluster" {
  source = "./modules/training-cluster"

  rancher2_access_key = var.rancher2_access_key
  rancher2_secret_key = var.rancher2_secret_key
  rancher2_api_url    = var.rancher2_api_url
  cloudscale_token    = var.cloudscale_token
  cluster_owner_group = var.cluster_owner_group
  node_flavor_master  = var.node_flavor_master
  node_flavor_worker  = var.node_flavor_worker
  node_count_master   = var.node_count_master
  node_count_worker   = var.node_count_worker
  network_plugin      = var.network_plugin
  ssh_keys            = var.ssh_keys

}
