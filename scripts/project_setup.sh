#!/usr/bin/env bash
##
## This script creates all the common Azure resources and GitHub Actions resources for the AzCopy-Runbook project
## Usage: ./project_setup.sh
##
## Resources include:
## - Common resource group
## - Common storage account & containers (tfstate & dsc)
## - Upload DSC script
## - Service principal used to execute Terraform
## - GitHub workflows
##
## DSC resources include:
## - dsc.ps1
##
## Dependencies:
## - az cli <https://learn.microsoft.com/en-us/cli/azure/install-azure-cli>
## - github cli <https://github.com/cli/cli>
## - jq <https://stedolan.github.io/jq>
## - zip

(
    cd "$(dirname "$0")/.." || exit
    set -euo pipefail

    # Configure environment variables
    if [ -f .env ]
    then
        set -o allexport; source .env; set +o allexport
    else 
        error "Missing .env file. Check .env.template"
    fi

    common_resource_group="${COMMON_PREFIX}-common-${UNIQUE_ID}-rg"
    common_storage_account="${COMMON_PREFIX}commonstor${UNIQUE_ID}"
    common_storage_tf_container="tfstate"
    common_storage_dsc_container="dsc"

    # Set subscription id
    subscriptionId=$(az account show --output tsv --query id)
    [[ -z "${subscriptionId}" ]] && error "Not logged into Azure. Run az login."

    # Set subscription name
    subscriptionName=$(az account show --output tsv --query name)
    [[ -z "${subscriptionName}" ]] && error "Not logged into Azure. Run az login,"

    # Set subscription tenant id
    subscriptionTenantId=$(az account show --output tsv --query tenantId)
    [[ -z "${subscriptionTenantId}" ]] && error "Not logged into Azure. Run az login"

    #####
    ##### Azure common resources setup
    #####

    # Create resource group
    echo "#### Creating resource resource group - ${common_resource_group} ####"
    az group create \
        --name "$common_resource_group" \
        --location "$COMMON_LOCATION" \
        --tags "Owner=$OWNER_EMAIL"

    # Create storage account
    echo "#### Creating storage account - ${common_storage_account} ####"
    az storage account create \
        --name "$common_storage_account" \
        --resource-group "$common_resource_group" \
        --location "$COMMON_LOCATION" \
        --sku Standard_LRS

    # Get storage account key
    accountKey=$(az storage account keys list --resource-group "${common_resource_group}" --account-name "${common_storage_account}" --query "[0].value" -o tsv)

    # Create blob container for Terraform state
    echo "#### Creating terraform storage container - ${common_storage_tf_container} ####"
    az storage container create \
        --name "$common_storage_tf_container" \
        --account-name "$common_storage_account" \
        --account-key "$accountKey"

    # Create blob container for DSC
    echo "#### Creating DSC storage container - ${common_storage_dsc_container} ####"
    az storage container create \
        --name "$common_storage_dsc_container" \
        --account-name "$common_storage_account" \
        --account-key "$accountKey"

    # Zip dsc.ps1 script
    zip -rj scripts/dsc/dsc.ps1.zip scripts/dsc/dsc.ps1

    # Upload the dsc zip file
    echo "#### Upload dsc zip ####"
    az storage blob upload \
        --account-name "$common_storage_account" \
        --account-key "$accountKey" \
        --file ./scripts/dsc/dsc.ps1.zip \
        --container-name "$common_storage_dsc_container" \
        --name dsc.ps1.zip \
        --overwrite

    # Create dsc sas token
    echo "#### Creating sas token ####"

    if [ "$OSTYPE" == "msys" ] || [ "$OSTYPE" == "linux-gnu" ]
    then
        expiry_date=$(date -d+10years +"%Y-%m-%d")
    else
        expiry_date=$(date -v+10y +"%Y-%m-%d")
    fi

    dscSasToken=$( \
        az storage container generate-sas \
            --account-name "$common_storage_account" \
            --account-key "$accountKey" \
            --name dsc \
            --https-only \
            --permissions r \
            --expiry "$expiry_date" \
            --output tsv)

    # Create identifiers for the terraform principal
    sname="${COMMON_PREFIX}-sp-common"
    name="http://${sname}"

    # Create the pipeline service principal
    echo "az ad sp create-for-rbac --name \"${name}\""

    if [ "$OSTYPE" == "msys" ]
    then
        # https://github.com/Azure/azure-cli/issues/16317
        spout=$(MSYS_NO_PATHCONV=1 az ad sp create-for-rbac \
            --role="Owner" \
            --scopes="/subscriptions/${subscriptionId}" \
            --name "${sname}" \
            --output json \
            --sdk-auth)
    else
        spout=$(az ad sp create-for-rbac \
            --role="Owner" \
            --scopes="/subscriptions/${subscriptionId}" \
            --name "${sname}" \
            --output json \
            --sdk-auth)
    fi

    # If the service principal has been created then reset credentials
    if [[ "$?" -ne 0 ]]
    then
        spout=$(az ad sp credential reset --name "${name}" --output json)
    fi

    [[ -z "${spout}" ]] && error "Failed to create / reset the service principal ${name}"

    #####
    ##### GitHub Actions setup
    #####

    export GITHUB_TOKEN="${GITHUB_ACCESS_TOKEN}"
    dscScriptUrl="https://${common_storage_account}.blob.core.windows.net/dsc/dsc.ps1.zip"
    clientId=$(jq -r .clientId <<< "$spout")
    clientSecret=$(jq -r .clientSecret <<< "$spout")
    tenantId=$(jq -r .tenantId <<< "$spout")

    # Set GitHub secrets
    gh secret set GH_ACCESS_TOKEN --repos "$GITHUB_REPO" --body "$GITHUB_TOKEN"
    gh secret set AZURE_CREDENTIALS --repos "$GITHUB_REPO" --body "$spout"
    gh secret set ARM_CLIENT_ID --repos "$GITHUB_REPO" --body "$clientId"
    gh secret set ARM_CLIENT_SECRET --repos "$GITHUB_REPO" --body "$clientSecret"
    gh secret set ARM_TENANT_ID --repos "$GITHUB_REPO" --body "$tenantId"
    gh secret set ARM_SUBSCRIPTION_ID --repos "$GITHUB_REPO" --body "$subscriptionId"
    gh secret set COMMON_PREFIX --repos "$GITHUB_REPO" --body "$COMMON_PREFIX"
    gh secret set UNIQUE_ID --repos "$GITHUB_REPO" --body "$UNIQUE_ID"
    gh secret set COMMON_RESOURCE_GROUP --repos "$GITHUB_REPO" --body "$common_resource_group"
    gh secret set COMMON_STORAGE_ACCOUNT --repos "$GITHUB_REPO" --body "$common_storage_account"
    gh secret set COMMON_STORAGE_TF_CONTAINER --repos "$GITHUB_REPO" --body "$common_storage_tf_container"
    gh secret set SOURCE_STORAGE_ACCOUNT_NAME --repos "$GITHUB_REPO" --body "$SOURCE_STORAGE_ACCOUNT_NAME"
    gh secret set SOURCE_STORAGE_ACCOUNT_KEY --repos "$GITHUB_REPO" --body "$SOURCE_STORAGE_ACCOUNT_KEY"
    gh secret set SOURCE_CONTAINER_OR_FILE_SHARE_NAME --repos "$GITHUB_REPO" --body "$SOURCE_CONTAINER_OR_FILE_SHARE_NAME"
    gh secret set TARGET_STORAGE_ACCOUNT_NAME --repos "$GITHUB_REPO" --body "$TARGET_STORAGE_ACCOUNT_NAME"
    gh secret set TARGET_STORAGE_ACCOUNT_KEY --repos "$GITHUB_REPO" --body "$TARGET_STORAGE_ACCOUNT_KEY"
    gh secret set TARGET_CONTAINER_OR_FILE_SHARE_NAME --repos "$GITHUB_REPO" --body "$TARGET_CONTAINER_OR_FILE_SHARE_NAME"
    gh secret set DSC_SCRIPT_URL --repos "$GITHUB_REPO" --body "$dscScriptUrl"
    gh secret set RUNBOOK_VM_USER_NAME --repos "$GITHUB_REPO" --body "$RUNBOOK_VM_USER_NAME"
    gh secret set RUNBOOK_VM_USER_PASSWORD --repos "$GITHUB_REPO" --body "$RUNBOOK_VM_USER_PASSWORD"
    gh secret set DSC_SCRIPT_SAS_TOKEN --repos "$GITHUB_REPO" --body "$dscSasToken"
)