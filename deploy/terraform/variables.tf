variable "location" {
  type        = string
  default     = "eastus"
  description = "The proper Azure location name for deployed resources."
}

variable "common_prefix" {
  type        = string
  description = "Azure resource name prefix."
}

variable "unique_id" {
  type        = string
  description = "Azure resoure name unique id."
}

variable "runbook_vm_admin_username" {
  type        = string
  description = "The username of the local administrator used for the runbook virtual machine"
}

variable "runbook_vm_admin_password" {
  type        = string
  description = "The password which should be used for the local-administrator on the runbook virtual machine"
}

variable "runbook_vm_size" {
  type        = string
  description = "The runbook virtual machine size"
  default     = "Standard_D4d_v4"
}

variable "runbook_vm_dsc_script_url" {
  type        = string
  description = "The Desired State Configuration (DSC) configuration script URL for the runbook virtual machine"
}

variable "runbook_vm_dsc_sas_token" {
  type        = string
  description = "The Desired State Configuration (DSC) configuration sas token for the runbook virtual machine"
}

variable "runbook_vm_dsc_script_name" {
  type        = string
  description = "The Desired State Configuration (DSC) configuration script name for the runbook virtual machine"
  default     = "dsc.ps1"
}

variable "runbook_vm_dsc_function_name" {
  type        = string
  description = "The Desired State Configuration (DSC) configuration function name for the runbook virtual machine"
  default     = "Main"
}
