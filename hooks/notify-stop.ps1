[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Get-SafeJsonInput {
    try {
        $raw = [Console]::In.ReadToEnd()
        if ([string]::IsNullOrWhiteSpace($raw)) { return [PSCustomObject]@{} }
        return ($raw | ConvertFrom-Json -ErrorAction Stop)
    }
    catch { return [PSCustomObject]@{} }
}

function Get-FirstCleanLine {
    param([string]$message, [int]$maxLength = 30)

    if ([string]::IsNullOrWhiteSpace($message)) { return "확인해 주세요" }

    $firstLine = (($message -split "`r?`n")[0]).Trim()
    if ([string]::IsNullOrWhiteSpace($firstLine)) { return "확인해 주세요" }

    $cleanLine = $firstLine `
        -replace '[*_#>\[\]\(\)]', '' `
        -replace '\s{2,}', ' '

    if ($cleanLine.Length -le $maxLength) { return $cleanLine }
    return ($cleanLine.Substring(0, $maxLength) + "...")
}

try {
    $payload  = Get-SafeJsonInput
    $cwd      = [string]$payload.cwd
    $lastMsg  = [string]$payload.last_assistant_message

    $folderName = if ([string]::IsNullOrWhiteSpace($cwd)) { "현재 작업" } else { Split-Path -Path $cwd -Leaf }
    $title = "[$folderName] Claude Code"
    $body  = "작업 완료 : $(Get-FirstCleanLine -message $lastMsg -maxLength 30)"

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    $safeTitle = [System.Security.SecurityElement]::Escape($title)
    $safeBody  = [System.Security.SecurityElement]::Escape($body)

    $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xmlDoc.LoadXml(
        '<toast activationType="protocol" launch="claude://">' +
        '<visual><binding template="ToastGeneric">' +
        '<text>' + $safeTitle + '</text>' +
        '<text>' + $safeBody  + '</text>' +
        '</binding></visual></toast>'
    )

    $toast    = [Windows.UI.Notifications.ToastNotification]::new($xmlDoc)
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code")
    $notifier.Show($toast)

    Write-Output "[OK] Stop notification sent."
    exit 0
}
catch {
    Write-Error "[FAIL] notify-stop.ps1: $($_.Exception.Message)"
    exit 1
}
