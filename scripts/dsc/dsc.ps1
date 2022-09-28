# DSC resource that installs azcopy
Configuration Main
{
    Param(
        [String]
        $InstallPath="C:\AzCopy",
        [String]
        $ZipFileName="C:\AzCopy\AzCopy.zip",
        [String]
        $AzCopyFileName="C:\AzCopy\azcopy.exe",
        [String]
        $AzCopyDownloadUri="https://aka.ms/downloadazcopy-v10-windows"
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node localhost
    {
        Script InstallAzCopy
        {
            GetScript = {
                $azCopyExists = Test-Path $using:AzCopyFileName
                return @{ 'Result' = "$azCopyExists" }
            }
            TestScript = {
                $state = [scriptblock]::Create($GetScript).Invoke()
                return $state.Result -eq "true"
            }
            SetScript = {
                # Create install folder
                $null = New-Item -Type Directory -Path $using:InstallPath -Force
                
                # Download AzCopy.zip
                Start-BitsTransfer -Source $using:AzCopyDownloadUri -Destination $using:ZipFileName
                
                # Expand the zip file
                Expand-Archive $using:ZipFileName $using:InstallPath -Force
                # Move azcopy.ext to install folder
                Get-ChildItem "$($using:InstallPath)\*\*" | Move-Item -Destination "$($using:InstallPath)\" -Force
                
                # Add the InstallPath to the system path

                if ($env:PATH -notcontains $using:InstallPath) {
                    $path = ($env:PATH -split ";")
                    if (!($path -contains $using:InstallPath)) {
                        $path += $using:InstallPath
                        $env:PATH = ($path -join ";")
                        $env:PATH = $env:PATH -replace ';;', ';'
                    }
                    [Environment]::SetEnvironmentVariable("Path", ($env:path), [System.EnvironmentVariableTarget]::Machine)
                }
            }
        }
    }
}