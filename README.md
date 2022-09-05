# Virtual Machine TF Module
This is a terraform project whitch automate the creation of virtual machine

# Init command
```bash
terraform init  -backend-config "bucket=warnerb47-terraform-states"  -backend-config "region=us-east-2"  -backend-config "key=dummy-project/vm-tf-module/terraform.tfstate"
```