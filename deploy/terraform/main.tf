terraform {
  backend "azurerm" {
  }

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "=0.4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  // Base resource name
  name = "${var.common_prefix}-${var.unique_id}"

  // Name with hyphens removed for resources that do not allow them
  sanitized_name = lower(replace(local.name, "/[^A-Za-z0-9]/", ""))
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${local.name}-${var.location}-rg"
  location = var.location
}
