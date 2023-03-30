# Acend Kubernetes Training Cluster Setup with Terraform



## Usage

Login into terraform cloud with your account using:

```bash
terraform login
```

Set your credentials (for the cloud provider and Rancher) e.g. in a `terraform.tfvars` File or using environment variables.

```bash
terraform init -backend-config=backend.hcl # only needed after initial checkout or when you add/change modules
terraform plan # to verify
terraform apply
```

## Variables


Check `main.tf` for an example cluster.