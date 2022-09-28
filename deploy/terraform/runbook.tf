resource "azurerm_automation_account" "account" {
  name                = "${local.name}-aa"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  sku_name            = "Basic"
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_automation_runbook" "runbook" {
  name                    = "azcopy-rb"
  resource_group_name     = azurerm_resource_group.resource_group.name
  location                = azurerm_resource_group.resource_group.location
  automation_account_name = azurerm_automation_account.account.name
  content                 = file("../../scripts/runbook/copy-runbook.ps1")
  log_progress            = false
  log_verbose             = false
  runbook_type            = "PowerShell"
}

resource "azapi_resource" "workergroup" {
  type      = "Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups@2021-06-22"
  name      = "${local.name}-hwg"
  parent_id = azurerm_automation_account.account.id
}

resource "random_uuid" "hrw" {
}

resource "azapi_resource" "worker" {
  type      = "Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups/hybridRunbookWorkers@2021-06-22"
  name      = random_uuid.hrw.result
  parent_id = azapi_resource.workergroup.id
  body = jsonencode({
    properties = {
      vmResourceId = azurerm_windows_virtual_machine.virtualmachine.id
    }
  })
}

resource "azurerm_automation_webhook" "webhook" {
  name                    = "${local.name}-wh"
  resource_group_name     = azurerm_resource_group.resource_group.name
  automation_account_name = azurerm_automation_account.account.name
  expiry_time             = "2022-12-31T00:00:00Z"
  enabled                 = true
  runbook_name            = azurerm_automation_runbook.runbook.name
  run_on_worker_group     = azapi_resource.workergroup.name
}
