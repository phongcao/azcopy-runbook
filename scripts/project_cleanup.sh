#!/usr/bin/env bash
##
## This script deletes all resources
##
## Usage: ./cleanup.sh
##
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

    # Delete resource group
    echo "#### Deleting resource group: ${common_resource_group} ####"
    az group delete \
        --name "$common_resource_group"

    # Delete github secrets
    export GITHUB_TOKEN="${GITHUB_ACCESS_TOKEN}"

    gh secret delete AZURE_CREDENTIALS --repo "$GITHUB_REPO"
    gh secret delete ARM_CLIENT_ID --repo "$GITHUB_REPO"
    gh secret delete ARM_CLIENT_SECRET --repo "$GITHUB_REPO"
    gh secret delete ARM_TENANT_ID --repo "$GITHUB_REPO"
    gh secret delete ARM_SUBSCRIPTION_ID --repo "$GITHUB_REPO"
    gh secret delete COMMON_PREFIX --repo "$GITHUB_REPO"
    gh secret delete UNIQUE_ID --repo "$GITHUB_REPO"
    gh secret delete COMMON_RESOURCE_GROUP --repo "$GITHUB_REPO"
    gh secret delete COMMON_STORAGE_ACCOUNT --repo "$GITHUB_REPO"
    gh secret delete COMMON_STORAGE_TF_CONTAINER --repo "$GITHUB_REPO"
    gh secret delete SOURCE_STORAGE_ACCOUNT_NAME --repo "$GITHUB_REPO"
    gh secret delete SOURCE_STORAGE_ACCOUNT_KEY --repo "$GITHUB_REPO"
    gh secret delete SOURCE_CONTAINER_OR_FILE_SHARE_NAME --repo "$GITHUB_REPO"
    gh secret delete TARGET_STORAGE_ACCOUNT_NAME --repo "$GITHUB_REPO"
    gh secret delete TARGET_STORAGE_ACCOUNT_KEY --repo "$GITHUB_REPO"
    gh secret delete TARGET_CONTAINER_OR_FILE_SHARE_NAME --repo "$GITHUB_REPO"
    gh secret delete DSC_SCRIPT_URL --repo "$GITHUB_REPO"
    gh secret delete RUNBOOK_VM_USER_NAME --repo "$GITHUB_REPO"
    gh secret delete RUNBOOK_VM_USER_PASSWORD --repo "$GITHUB_REPO"
    gh secret delete DSC_SCRIPT_SAS_TOKEN --repo "$GITHUB_REPO"
)