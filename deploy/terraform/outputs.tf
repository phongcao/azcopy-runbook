output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.resource_group.name
}

output "automation_account_name" {
  description = "Name of the automation account"
  value       = azurerm_automation_account.account.name
}

output "runbook_webhook_uri" {
  description = "Runbook webhook URI"
  value       = azurerm_automation_webhook.webhook.uri
  sensitive   = true
}
