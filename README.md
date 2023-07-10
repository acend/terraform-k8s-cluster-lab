# Acend Kubernetes Training Cluster Setup with Terraform

## Overview

This setup provisions a Kubernetes Cluster to be used with our trainings.

We use [Hetzner](https://www.hetzner.com/cloud) as our cloud provider and [RKE2](https://docs.rke2.io/) to create the kubernetes cluster. [Kubernetes Cloud Controller Manager for Hetzner Cloud](https://github.com/hetznercloud/hcloud-cloud-controller-manager) to provision lobalancer from a Kubernetes service (type `Loadbalancer`) objects and also configure the networking & native routing for the Kubernetes cluster network traffic.

Cluster setup is based on our [infrastructure](https://github.com/acend/infrastructure) setup.

In order to deploy our acend Kubernetes Cluster the following steps are necessary:

1. Terraform to deploy base infrastructure
   * VM's for controlplane and worker nodes
   * Network
   * Loadbalancer for Kubernetes API and RKE2
   * Firewall
   * Hetzner Cloud Controller Manager for the Kubernetes Cluster Networking
   * Storage Provisioner (hcloud csi, longhorn)
   * Ingresscontroller
   * Cert-Manager
   * Gitea
2. Terraform to deploy and bootstrap ArgoCD
3. ArgoCD to deploy resources student/user resources

For more details on the cluster design and setup see the [documentation](https://github.com/acend/infrastructure/tree/main/docs#cluster-basic-design--configuration-and-setup-procedure) in our main infrastructure repository.

### Components

#### argocd

ArgoCD is used to deploy components (e.g.) onto the cluster. ArgoCD is also used for the training itself.

There is a local `admin` account. The password can be extracted with `terraform output argocd-admin-password`

Each student/user also get a local account.

#### cert-manager

[Cert Manager](https://cert-manager.io/) is used to issue Certificates (Let's Encrypt).
The [ACME Webhook for the hosttech DNS API](https://github.com/piccobit/cert-manager-webhook-hosttech) is used for `dns01` challenges with our DNS provider.

The following `ClusterIssuer` are available:

* `letsencrypt-prod`: for general http01 challenge.
* `letsencrypt-prod-acend`: for dns01 challenge using the hosttech acme webhook. The token for hosttech is stored in the `hosttech-secret` Secret in Namespace `cert-manager`

#### Hetzner Kubernetes Cloud Controller Manager

The [Kubernetes Cloud Controller Manager for Hetzner Cloud](https://github.com/hetznercloud/hcloud-cloud-controller-manager) is deployed and allows to provision LoadBalancer based on Services with type `LoadBalancer`.
The Cloud Controller Manager is also resposible to create all the necessary routes between the Kubernete Nodes. See [Network Support](https://github.com/hetznercloud/hcloud-cloud-controller-manager#networks-support) for details.

#### Hetzner CSI

To provision storage we use [Hetzner CSI Driver](https://github.com/hetznercloud/csi-driver).

The StorageClass `hcloud-volumes` is available. Be aware, `hcloud-volumes` are provisioned at our cloud provider and do cost. Furthermore we have [limits](https://docs.hetzner.com/cloud/volumes/faq/#is-there-a-limit-on-the-number-of-attached-volumes) ou how much storage we can provision or more precise, attache to a VM.

#### Ingresscontroller: haproxy

[haproxy](https://github.com/haproxytech/helm-charts/tree/main/kubernetes-ingress) is used as ingress controller. `haproxy` is the default IngressClass

#### Longhorn

As our Kubernetes Nodes have enough local disk available, we use [longhorn](https://longhorn.io/) as a additional storage solution. The `longhorn` storageclass is set as the default storage class.

#### Gitea

We use a local [Gitea](https://about.gitea.com/) installation that is used in our trainings.

## Training Environment

The training environment contains the following per student/user:

* Credentials
* All necessary namespaces
* RBAC to access the namespaces
* a [Webshell](https://github.com/acend/webshell-env) per student/user.
* a Gitea account and a Git repository clone of our [argocd-training-example](https://github.com/acend/argocd-training-examples.git)

It is deployed with ArgoCD using ApplicationSets. The ApplicationSets are deployed with Terraform

## Usage

This repo can be used standalone or included as module from an other repo.

Currently we use terraform cloud as state backend. Login into terraform cloud with your account using:

```bash
terraform login
```

Set your credentials (for the cloud provider and Rancher) e.g. in a `terraform.tfvars` File or using environment variables.

```bash
terraform init -backend-config=backend.hcl # only needed after initial checkout or when you add/change modules
terraform plan # to verify
terraform apply
```

### inluded as module

See [training-setup](https://github.com/acend/training-setup) for an example

## Variables

Check `main.tf` for an example cluster.
