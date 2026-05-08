# Notification 훅 알림: 이벤트 타입별 문구 매핑
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Get-SafeJsonInput {
    try {
        $raw = [Console]::In.ReadToEnd()
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return [PSCustomObject]@{}
        }

        return ($raw | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        return [PSCustomObject]@{}
    }
}

function Get-NotificationPrefix {
    param([string]$notificationType)

    $safeType = if ($null -eq $notificationType) { "" } else { [string]$notificationType }
    switch ($safeType.ToLowerInvariant()) {
        "success" { return "[완료]" }
        "info" { return "[분석]" }
        "warning" { return "[수정]" }
        "error" { return "[오류]" }
        default { return "[알림]" }
    }
}

try {
    $payload = Get-SafeJsonInput
    $notificationType = [string]$payload.notification_type
    $message = [string]$payload.message
    $source = [string]$payload.source

    $prefix = Get-NotificationPrefix -notificationType $notificationType
    $title = "$prefix Claude Code Notification"

    $normalizedMessage = if ([string]::IsNullOrWhiteSpace($message)) {
        "세부 메시지가 없습니다."
    }
    else {
        $message.Trim()
    }

    $body = if ([string]::IsNullOrWhiteSpace($source)) {
        $normalizedMessage
    }
    else {
        "$source - $normalizedMessage"
    }

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    $xml = @"
<toast>
  <visual>
    <binding template='ToastGeneric'>
      <text>$title</text>
      <text>$body</text>
    </binding>
  </visual>
  <actions>
    <action content="화면으로" activationType="protocol" arguments="claude-focus://open"/>
  </actions>
</toast>
"@

    $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xmlDoc.LoadXml($xml)

    $toast = [Windows.UI.Notifications.ToastNotification]::new($xmlDoc)
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code")
    $notifier.Show($toast)

    Write-Output "[OK] Notification sent. type=$notificationType"
    exit 0
}
catch {
    Write-Error "[FAIL] notify-user.ps1: $($_.Exception.Message)"
    exit 1
}
