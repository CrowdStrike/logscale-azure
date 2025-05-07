# README.md
These example files are provided for quick start options to using the provided terraform. Replace main.tf with the desired configuration.

## full-no-bastion.tf
This is the expected default build in the repository primary README.md that results in creation of an architecture that is publicly available for ingestion and access but controlled with IP restrictions applied via network security groups. The automation will also create a valid TLS certificate using Let's Encrypt as the certificate authority. 

```
export TFVAR_FILE=/path/to/myfile.tfvars
az login
ln -s repository-path/examples/full-no-bastion.tf repository-path/main.tf
terraform init -upgrade
terraform apply -target module.azure-core -target module.azure-keyvault -target module.azure-kubernetes -target module.logscale-storage-account -var-file $TFVAR_FILE
az aks get-credentials --resource-group ${var.name_prefix}-rg --name aks-${var.name_prefix}
terraform apply -target module.crds -var-file $TFVAR_FILE
terraform apply -target module.logscale-prereqs -var-file $TFVAR_FILE
terraform apply -target module.kafka -var-file $TFVAR_FILE
terraform apply -target module.logscale -var-file $TFVAR_FILE
```

## full-with-bastion.tf
This infrastructure build adds in a bastion host. The bastion host is a dedicated system available via SSH with a public IP address that you can leverage to manage the infrastructure as necessary. The purpose of the bastion host is largely for handling when setting `var.kubernetes_private_cluster_enabled` to `true`. In this scenario, the kubernetes API will only be available within the VNET containing the infrastructure built by this terraform.

```
export TFVAR_FILE=/path/to/myfile.tfvars
az login
ln -s repository-path/examples/full-with-bastion.tf repository-path/main.tf
terraform init -upgrade
terraform apply -target module.azure-core -target module.azure-keyvault -target module.azure-kubernetes -target module.logscale-storage-account -target module.bastion-host-1 -var-file $TFVAR_FILE
az aks get-credentials --resource-group ${var.name_prefix}-rg --name aks-${var.name_prefix}
terraform apply -target module.crds -var-file $TFVAR_FILE
terraform apply -target module.logscale-prereqs -var-file $TFVAR_FILE
terraform apply -target module.kafka -var-file $TFVAR_FILE
terraform apply -target module.logscale -var-file $TFVAR_FILE
```

## full-with-self-cert.tf
This infrastructure is the same as `full-no-bastion.tf` except it disables the use of Let's Encrypt and leverages a self-signed certificate stored in Azure Keyvault instead.

```
export TFVAR_FILE=/path/to/myfile.tfvars
az login
ln -s repository-path/examples/full-with-self-cert.tf repository-path/main.tf
terraform init -upgrade
terraform apply -target module.azure-core -target module.azure-keyvault -target module.azure-kubernetes -target module.logscale-storage-account -target module.azure-selfsigned-cert -var-file $TFVAR_FILE
az aks get-credentials --resource-group ${var.name_prefix}-rg --name aks-${var.name_prefix}
terraform apply -target module.crds -var-file $TFVAR_FILE
terraform apply -target module.logscale-prereqs -var-file $TFVAR_FILE
terraform apply -target module.kafka -var-file $TFVAR_FILE
terraform apply -target module.logscale -var-file $TFVAR_FILE
```