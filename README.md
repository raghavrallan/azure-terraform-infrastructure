# ZTFortio

This is the top-level Terraform project for provisioning infrastructure
for the ZTFortio application.

## Layers


This AzureCICD project (azure-ci-cd) is broken into the following layers:

| **Layer**          | **Description**                                             |
|--------------------|-------------------------------------------------------------|
| Env                | It contains the Environment wise configurations.            |
| modules            | The associated modules related to CI/CD are placed herewith |


This Terraform project (azure-terraform) is broken into the following layers:

| **Layer**          | **Description**                                             |
|--------------------|-------------------------------------------------------------|
| _main              | Initial boostrap layer for creating Terraform state storage |
| 100_base           | Top level resources per environment                         |
| 200_tenant_storage | Blob storage that is tenant specific                        |
| 300_database       | Operational databases and schema                            |
| 400_backend        | Micro-service support                                       |
| modules            | Common modules that will be used accrose all layers         |


The terraform state is managed per layer and per environment to allow for
independent releases of the layers into their respective environments:

## Environments

| **Environment** | **Description**                         |
|-----------------|-----------------------------------------|
| uat              | Testing and quality assurance           |
| prod            | Production                              |

## Azure Resource Naming Conventions

https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

---

## 🚀 Quick Start - Automated Deployment

For a quick and automated deployment of the entire infrastructure, use the provided deployment scripts:

### Windows (PowerShell)
```powershell
# Deploy entire infrastructure with one command
.\deploy-infrastructure.ps1
```

### Linux/Mac/Git Bash
```bash
# Deploy entire infrastructure with one command
chmod +x deploy-infrastructure.sh
./deploy-infrastructure.sh
```

### What Gets Deployed Automatically

The automated deployment scripts will:
- ✅ Check all prerequisites (Azure CLI, Terraform, Docker, OpenSSL)
- ✅ Deploy base layer (100_base) with VNet, subnets, Key Vault
- ✅ Generate and upload SSL certificate
- ✅ Deploy backend layer (400_backend) with Application Gateway and Container Apps
- ✅ Build and push sample API Docker image
- ✅ Verify deployment and run health checks
- ✅ Display summary with test commands

**Total deployment time**: ~15-20 minutes

### Cleanup
```powershell
# Windows: Destroy all infrastructure
.\destroy-infrastructure.ps1

# You will be prompted to confirm by typing "DELETE"
```

📚 **For detailed documentation**, see [DEPLOYMENT_SCRIPTS_README.md](DEPLOYMENT_SCRIPTS_README.md)

---

## First Deployment to an Environment

The very first time that Terraform is executed for a specific environment i.e. uat, prod you will
need to run Terraform in the _main layer as shown below, but first you will need to log into azure,
or set your environment variables with credentials that will allow the Azure CLI to make changes:

```bash
$ az login
```

```bash
$ cd terraform/layers/_main/env/uat
$ terraform init
$ terraform apply -auto-approve
```

This will create the resource group and storage account and blob container that keeps track of the
remote Terraform state for the environment.  Multiple files will be created in this container, one
for each layer.

Note that by changing into the env/uat folder the terraform command is using the provider and
variables from that folder, so you do not need to specify variables on the command line unless
you are overriding the variables.  The subscription ID is also set for each environment to
make sure that the proper subscription is chosen for where the resources are being deployed.

## Deployment to an Environment

Once the _main layer exists, it is recommended that you apply changes to the layer in numerical
order.  For example, changes to 100_base should be applied before 200_datalake.  The reason that
the scripts are broken into different layers is to allow for independent deployment of the layers
without having to re-deploy the entire stack every time.  For example, if only the backend changes,
you only need to apply the changes for 400_backend for the specific environment you are working in
i.e. 'uat'.  The environments are specifically broken into sztfarate sub-folders so that mistakes
in the subscription IDs, the environment names, and the state file names used by the provider
can not happen.  This also helps to work around the Terraform restriction that the terraform
block regarding remote state storage does not support variable injection.

```bash
$ az login
```

```bash
$ cd terraform/layers/100_base/env/uat
$ terraform init
$ terraform apply -auto-approve
```