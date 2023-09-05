# Demo Terraform Minecraft

This repository shows how to use a Github actions based workflow to test and apply Terraform
using a branch based methodology.

## Strucuture

### Github Actions

**.github/workflows/build.yml**  
Example GitHub action which uses an API driven workflow with Terraform cloud
to build and test an application, test the Terraform configuration for deployment.
And finally deploy the application using Terraform Cloud.

**github/workflows/pr.yml**  
Example GitHub action that uses a Terraform cloud API driven workflow to 
run a speculative plan for the to be merged configuration. The action 
reports changes to the PR and links to the Terraform cloud plan for further 
info.

## Terraform

**terraform/hcp**  
Example Terraform that creates a Vault cluster using HashiCorp cloud.

**terraform/gcp/core**  
Example Terraform to create a Kubernetes cluster in GCP along with a public
service to enable access.

**terraform/gcp/app**  
Example application that uses Terraform to deploy a Minecraft server to Kubernetes.
The configuration also configures userpass and secrets in Vault.
