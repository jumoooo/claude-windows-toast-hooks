# Windows 알림 AppUserModelId(AUMID) 등록 스크립트
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

try {
    $appId = "Claude Code"
    $registryPath = "HKCU:\Software\Classes\AppUserModelId\$appId"

    if (-not (Test-Path -Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }

    # 알림 센터에서 식별될 기본 표시 이름
    New-ItemProperty -Path $registryPath -Name "DisplayName" -PropertyType String -Value $appId -Force | Out-Null

    # claude-focus:// URI 스킴 등록 — focus-claude.ps1 핸들러 연결 (idempotent)
    $focusRoot = "HKCU:\Software\Classes\claude-focus"
    if (-not (Test-Path "$focusRoot\shell\open\command")) {
        New-Item -Path "$focusRoot\shell\open\command" -Force | Out-Null
        Set-ItemProperty $focusRoot    "(default)"    "URL:Claude Focus Protocol"
        Set-ItemProperty $focusRoot    "URL Protocol" ""
        Set-ItemProperty "$focusRoot\shell\open\command" "(default)" `
            "powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -File `"$PSScriptRoot\focus-claude.ps1`""
    }

    Write-Output "[OK] AUMID registered: $registryPath / URI scheme: claude-focus://"
    exit 0
}
catch {
    Write-Error "[FAIL] setup-appid.ps1: $($_.Exception.Message)"
    exit 1
}
