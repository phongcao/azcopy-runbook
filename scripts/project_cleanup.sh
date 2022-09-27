#!/usr/bin/env bash
##
## This script deletes all resources in specified environment
##
## Usage: ./cleanup.sh <env>
## Example: ./cleanup.sh dev
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
)