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

function Get-NotificationPrefix {
    param([string]$notificationType)

    $safeType = if ($null -eq $notificationType) { "" } else { [string]$notificationType }
    switch ($safeType) {
        "permission_prompt"  { return "권한 요청" }
        "idle_prompt"        { return "응답 대기" }
        "auth_success"       { return "인증 완료" }
        "elicitation_dialog" { return "입력 필요" }
        default              { return "응답 대기" }
    }
}

try {
    $payload      = Get-SafeJsonInput
    $cwd          = [string]$payload.cwd
    $notifType    = [string]$payload.notification_type
    $message      = [string]$payload.message

    $folderName = if ([string]::IsNullOrWhiteSpace($cwd)) { "현재 작업" } else { Split-Path -Path $cwd -Leaf }
    $prefix = Get-NotificationPrefix -notificationType $notifType
    $title  = "[$folderName] Claude Code"
    $body   = if ([string]::IsNullOrWhiteSpace($message)) { "${prefix} 중입니다" } else { "${prefix} : $($message.Trim())" }

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

    Write-Output "[OK] Notification sent. type=$notifType"
    exit 0
}
catch {
    Write-Error "[FAIL] notify-user.ps1: $($_.Exception.Message)"
    exit 1
}
