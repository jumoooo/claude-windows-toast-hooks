# 알림 클릭 시 Claude 관련 창을 전면으로 활성화
# claude-focus:// URI 스킴 핸들러 — setup-appid.ps1 이 레지스트리에 등록
[CmdletBinding()]
param()

# URI 핸들러는 창이 없어도 조용히 종료해야 하므로 SilentlyContinue
$ErrorActionPreference = "SilentlyContinue"

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class Win32Focus {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
}
'@

# 방식 B: 열린 창 1회 수집 후 메모리 내 우선순위 필터
# SetForegroundWindow 는 사용자 클릭(알림)으로 시작된 프로세스에 자동 허용됨
$openWindows = Get-Process -ErrorAction SilentlyContinue |
               Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero }

# 우선순위: CLI 호스트(WT, VSCode) → Claude Desktop → PowerShell
$priority = "WindowsTerminal", "Code", "claude", "pwsh", "powershell"
$target   = $null

foreach ($name in $priority) {
    $proc = $openWindows |
            Where-Object { $_.ProcessName -eq $name } |
            Select-Object -First 1
    if ($proc) { $target = $proc; break }
}

if ($target) {
    try {
        $hwnd = $target.MainWindowHandle
        if ([Win32Focus]::IsIconic($hwnd)) {
            [void][Win32Focus]::ShowWindow($hwnd, 9)  # SW_RESTORE
            Start-Sleep -Milliseconds 100
        }
        [void][Win32Focus]::SetForegroundWindow($hwnd)
    }
    catch {}
}

exit 0
