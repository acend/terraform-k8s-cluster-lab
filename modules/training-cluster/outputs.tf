output "kube_config_raw" {
  value = rancher2_cluster_sync.training.kube_config
}


output "kube_config" {
  value = yamldecode(rancher2_cluster_sync.training.kube_config)
}