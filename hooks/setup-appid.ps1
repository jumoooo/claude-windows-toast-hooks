[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

try {
    $appId = "Claude Code"
    $registryPath = "HKCU:\Software\Classes\AppUserModelId\$appId"

    if (-not (Test-Path -Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }

    New-ItemProperty -Path $registryPath -Name "DisplayName" -PropertyType String -Value $appId -Force | Out-Null

    Write-Output "[OK] AUMID registered: $registryPath"
    exit 0
}
catch {
    Write-Error "[FAIL] setup-appid.ps1: $($_.Exception.Message)"
    exit 1
}
