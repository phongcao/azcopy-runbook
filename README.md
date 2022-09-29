# AzCopy-Runbook

This is the main readme for the AzCopy-Runbook project.

[![CI](https://github.com/phongcao/azcopy-runbook/actions/workflows/ci.yml/badge.svg)](https://github.com/phongcao/azcopy-runbook/actions/workflows/ci.yml)

## Overview

This project is intended to serve two purposes:

1. A reference implementation that demonstrates the creation of the
Azure resources needed to support an automation hybrid worker runbook
using Terraform and GitHub Actions.
2. A cloud based azcopy "utility" that can be used to perform a
performant/high scale azcopy operation in the cloud.

## Repo Structure

Folder            | Description
--                | --
./.github         | GitHub Actions YAML files
depoy/terraform   | Terraform scripts used to create the Azure resources
scripts           | Project setup & cleanup scripts
scripts/dsc       | DSC (Desired State Configuration) PowerShell script
scripts/runbook   | Runbook PowerShell script

## AzCopy Cloud Utility

### Dependencies

- [az cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [github cli](https://github.com/cli/cli)
- [jq](https://stedolan.github.io/jq)
- [zip - Windows Only](https://gnuwin32.sourceforge.net/packages/zip.htm)

### Initial Setup

1. Create a GitHub PAT (Personal Access Token) for automated DevOps
resource creation used by project_setup.sh.
2. Create a local `.env` file in the root folder by copying
the [.env.template](.env.template) file.
3. Populate the `.env` file with values specific to your environment.
4. Run `az login` command and sign in to your Azure account. You need to
be an owner of your subscription so that you can create a service principal
used for Azure resources deployment.
5. Run [scripts/project_setup.sh](scripts/project_setup.sh).

### Workflow Setup

1. Run the `CI` workflow to create the Azure resources.
2. Run the `AzCopy` workflow to initiate an azcopy operation. The source
and target file share/container can be specified in the `.env` file or as
workflow parameters.
