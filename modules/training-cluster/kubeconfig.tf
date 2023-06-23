locals {
  kubernetes_api_ipv4    = hcloud_load_balancer.lb.ipv4
  kubernetes_api_ipv6    = hcloud_load_balancer.lb.ipv6
  kubernetes_api         = "https://${hcloud_load_balancer.lb.ipv4}:6443"
  kubeconfig_raw         = replace(ssh_resource.getkubeconfig.result, "server: https://127.0.0.1:6443", "server: ${local.kubernetes_api}")
  kubeconfig             = yamldecode(local.kubeconfig_raw)
  client_certificate     = base64decode(local.kubeconfig.users[0].user.client-certificate-data)
  client_key             = base64decode(local.kubeconfig.users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster.certificate-authority-data)
}

resource "null_resource" "wait_for_k8s_api" {

  triggers = {
    k8s_api_ip = hcloud_load_balancer.lb.ipv4
  }
  provisioner "local-exec" {
    command     = <<EOH
while true; do
    curl -k https://$K8S_API_IP:6443 && break || sleep 3
done
EOH
    interpreter = ["/bin/bash", "-c"]
    environment = {
      K8S_API_IP = self.triggers.k8s_api_ip
    }
  }

  depends_on = [
    hcloud_server.controlplane,
    hcloud_server.worker,
    hcloud_server_network.controlplane,
    hcloud_firewall.firewall,
    hcloud_load_balancer_service.api,
    hcloud_load_balancer_target.controlplane
  ]
}

resource "ssh_resource" "getkubeconfig" {

  depends_on = [
    null_resource.wait_for_k8s_api
  ]

  when = "create"

  host = hcloud_server.controlplane[0].ipv4_address
  user = "root"

  private_key = tls_private_key.terraform.private_key_openssh

  timeout     = "15m"
  retry_delay = "5s"

  commands = [
    "until [ -f /etc/rancher/rke2/rke2.yaml ]; do sleep 10; done;",
    "cat /etc/rancher/rke2/rke2.yaml"
  ]
}
