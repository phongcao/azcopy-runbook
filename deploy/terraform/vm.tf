resource "azurerm_virtual_network" "virtualnetwork" {
  name                = "${local.name}-vnet"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${local.name}-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtualnetwork.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "networkinterface" {
  name                = "${local.name}-nic"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.name}-nsg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.networkinterface.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "virtualmachine" {
  name                = "${local.name}-vm"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  computer_name       = "runbook-vm"
  size                = var.runbook_vm_size
  zone                = "1"
  admin_username      = var.runbook_vm_admin_username
  admin_password      = var.runbook_vm_admin_password
  network_interface_ids = [
    azurerm_network_interface.networkinterface.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    offer     = "windows-11"
    publisher = "microsoftwindowsdesktop"
    sku       = "win11-21h2-pro"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

data "azapi_resource" "hybrid_service_url" {
  name      = azurerm_automation_account.account.name
  parent_id = azurerm_resource_group.resource_group.id
  type      = "Microsoft.Automation/AutomationAccounts@2021-06-22"

  response_export_values = ["properties.automationHybridServiceUrl"]

  depends_on = [
    azurerm_windows_virtual_machine.virtualmachine,
    azurerm_automation_account.account
  ]
}

resource "azurerm_virtual_machine_extension" "hybrid_worker_extension" {
  name                        = "HybridWorkerExtension"
  virtual_machine_id          = azurerm_windows_virtual_machine.virtualmachine.id
  publisher                   = "Microsoft.Azure.Automation.HybridWorker"
  type                        = "HybridWorkerForWindows"
  type_handler_version        = "0.1"
  auto_upgrade_minor_version  = false
  automatic_upgrade_enabled   = false

  depends_on = [
    data.azapi_resource.hybrid_service_url
  ]

  settings = <<SETTINGS
    {
        "AutomationAccountURL": "${jsondecode(data.azapi_resource.hybrid_service_url.output).properties.automationHybridServiceUrl}"
    }
  SETTINGS
}

resource "azurerm_virtual_machine_extension" "dsc" {
  name                       = "Install-DSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.virtualmachine.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.9"
  auto_upgrade_minor_version = true
  depends_on = [
    azurerm_windows_virtual_machine.virtualmachine
  ]

  settings = <<SETTINGS
    {
        "configuration": {
            "url": "${var.runbook_vm_dsc_script_url}",
            "script": "${var.runbook_vm_dsc_script_name}",
            "function": "${var.runbook_vm_dsc_function_name}"
        }
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "configurationUrlSasToken": "?${var.runbook_vm_dsc_sas_token}"
    }
  PROTECTED_SETTINGS
}
