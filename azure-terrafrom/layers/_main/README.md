# _main

This layer should be executed only once per environment to estatblish the remote state storage
that Terraform uses for configuration.  Once this layer exists, it is used for keeping track
of changes to the environments as well as the data that is output to allow communicating
between the layers i.e 100_base <- 200_datalake.  It is the case that a higher numbered layer
may access data from a lower number layer, but a lower numbered layer may never access data
from a higher numbered layer.  For example, 200_datalake -> 300_integration is not allowed. 

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| env | The name of the environment, e.g. prod, dev, uat | string | n/a | yes |

## Outputs

Creates a resource group, storage account, and storage container for terraform_remote_state
that is stored on Azure blob storage that is referenced from provider backends and as a
data source within the numbered layers.
