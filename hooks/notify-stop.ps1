# Stop 훅 알림: 작업 종료 시 요약 메시지 표시
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
        # 입력 JSON이 깨졌을 때도 훅이 전체 실패하지 않도록 기본값 반환
        return [PSCustomObject]@{}
    }
}

function Get-FirstCleanLine {
    param(
        [string]$message,
        [int]$maxLength = 30
    )

    if ([string]::IsNullOrWhiteSpace($message)) {
        return "요약 메시지가 없습니다."
    }

    $firstLine = (($message -split "`r?`n")[0]).Trim()
    if ([string]::IsNullOrWhiteSpace($firstLine)) {
        return "요약 메시지가 없습니다."
    }

    # 마크다운 기호를 줄여 알림 본문을 읽기 쉽게 유지
    $cleanLine = $firstLine `
        -replace "[`*_#>\[\]\(\)]", "" `
        -replace "\s{2,}", " "

    if ($cleanLine.Length -le $maxLength) {
        return $cleanLine
    }

    return ($cleanLine.Substring(0, $maxLength) + "...")
}

try {
    $payload = Get-SafeJsonInput
    $cwd = [string]$payload.cwd
    $lastAssistantMessage = [string]$payload.last_assistant_message

    $folderName = if ([string]::IsNullOrWhiteSpace($cwd)) {
        "현재 작업"
    }
    else {
        Split-Path -Path $cwd -Leaf
    }

    $title = "[$folderName] Claude Code"
    $body = "작업 완료 : $(Get-FirstCleanLine -message $lastAssistantMessage -maxLength 30)"

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
</toast>
"@

    $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xmlDoc.LoadXml($xml)

    $toast = [Windows.UI.Notifications.ToastNotification]::new($xmlDoc)
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code")
    $notifier.Show($toast)

    Write-Output "[OK] Stop notification sent."
    exit 0
}
catch {
    Write-Error "[FAIL] notify-stop.ps1: $($_.Exception.Message)"
    exit 1
}
