# Lab Cluster Setup with Terraform

WIP!
This is currently desiged to run on our Rancher Control Plane and probably does not work out of the box.

## Requirements

* https://github.com/banzaicloud/terraform-provider-k8s

## Usage

* You have to create a Node Template on your Rancher Control Plane as the rancher2 provider currently does not support non default node templates (we use cloudscale). `acend GmbH - flex-8 - 50 GB Root` is used by default.


## Variables

```
# An access key for a rancher control plane
variable "rancher2_access_key" {
    type = string
}

# A secret key for a rancher control plane
variable "rancher2_secret_key" {
    type = string
}

# A cloudscale api token used to deploy vm's and for cloudscale-csi
variable "cloudscale_token" {
    type = string
}

# Hostname of a Rancher Control Plane
variable "rancher2_api_url" {
    type = string
}
``` 