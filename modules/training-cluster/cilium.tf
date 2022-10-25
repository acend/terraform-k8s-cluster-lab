# Deploy Cilium CNI if enabled
module "cilium" {
  source = "./modules/cilium"

  depends_on = [rancher2_cluster_sync.training]

  rancher_system_project = data.rancher2_project.system
  public_ip              = replace(cloudscale_floating_ip.vip-v4.network, "/32", "")

  count = local.cilium_enabled
}