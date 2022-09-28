Param (
  # JSON formatted input.
  [object] $WebhookData
)

if (-Not $WebhookData.RequestBody) {
    $WebhookData = (ConvertFrom-Json -InputObject $WebhookData)
}

# Parse params
$requestBody = $WebhookData.RequestBody | ConvertFrom-Json
$sourceSASURI = $requestBody.sourceSASURI
$targetSASURI = $requestBody.targetSASURI

# Refresh PATH
$registryPath = "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment"
$env:path = Get-ItemProperty -Path $registryPath -Name PATH

# Invoke AzCopy
azcopy copy $sourceSASURI $targetSASURI --recursive=true --overwrite=true