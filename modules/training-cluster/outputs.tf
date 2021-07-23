output "kube_config_raw" {
  value = rancher2_cluster_sync.training.kube_config
}


output "kube_config" {
  value = yamldecode(rancher2_cluster_sync.training.kube_config)
}


output "reg_token" {
  value = rancher2_cluster.training.cluster_registration_token[0].node_command
}