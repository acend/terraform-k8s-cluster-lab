# Lab Cluster Setup with Terraform

WIP!
This is currently desiged to run on our Rancher Control Plane and probably does not work out of the box.

## Requirements



* Access to a Rancher Management Server with permissions to create a new cluster
* A cloudscale.ch Account for the VM's


## Usage

Set your credentials e.g. in a `terraform.tfvars` File or using environment variables

```
terraform init # only needed after initial checkout or when you add/change modules
terraform plan # to verify
terraform apply
```


## Variables

Make sure you have set at least the following variables. See `variables.tf` for all possible variables.



```
# An access key for a rancher control plane
variable "rancher2_access_key" {
    type = string
}

# A secret key for a rancher control plane
variable "rancher2_secret_key" {
    type = string
}

# Hostname of a Rancher Control Plane
variable "rancher2_api_url" {
    type = string
}

# A cloudscale api token used to deploy vm's and for cloudscale-csi
variable "cloudscale_token" {
    type = string
}

variable "ssh_keys" {
    description = "SSH Public keys with access to the cloudscale.ch VM's"
    type = list(string)
    default = []
}

variable "cluster_owner_group" {
    description = "The group_principal_id of a Rancher group which will become cluster owner"
    type = string
    default = ""
}
``` 

### Deploy Cluster with Canal SDN

canal is the default network plugin and is set with the variable `network_plugin=canal`


### Deploy Cluster with Canal SDN

Change the variable `network_plugin` to `cilium` if you want to deploy Cilium as your SDN.