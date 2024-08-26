# Azure Infrastructure

![main.yaml](https://github.com/TanmayDharmaraj/azure-infrastructure/actions/workflows/main.yaml/badge.svg)

The repository is structured as below

## Folder structure
- [.vscode](./.vscode/extensions.json): You can use this in vscode to install the recommended extension
- [workflow (ci/cd)](./.github/workflows/main.yaml): Contains the github workflow to lint, validate and deploy the infrastructure
- [main.bicep](./main.bicep): Serves as the main deployment file that deploys the entire infrastructure
- [main.bicepparam](./main.bicepparam): Parameter file that is used to deploy the infrastructure
- [modules](./modules): This folder contains the modules that deploy storage account, key vault etc.