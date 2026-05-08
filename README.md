# Claude Windows Toast Hooks

> Windows 전용 저장소입니다. (macOS/Linux 미지원)
<img width="322" height="399" alt="image" src="https://github.com/user-attachments/assets/83860338-d86d-4262-8ee1-8f068be7ed2f" />


Claude Code 훅 중 **안정형 3종(SessionStart, Stop, Notification)** 만 분리한 복붙형 레포입니다.
개인 계정/토큰/프로젝트별 민감 설정 없이, 훅 스크립트와 최소 설정 예제만 제공합니다.

## 빠른 시작

1. 이 레포에서 `hooks` 폴더와 `settings.example.json`을 복사해 원하는 위치에 둡니다.
2. `settings.example.json`의 `hooks` 블록을 Claude 설정 파일의 `hooks`에 병합합니다.
3. `SessionStart` 훅이 먼저 실행되어 AUMID(AppUserModelId, Windows 알림 식별자)를 등록하도록 확인합니다.

### settings.json 위치

| 범위 | 경로 |
|------|------|
| 전역 (모든 프로젝트) | `%USERPROFILE%\.claude\settings.json` |
| 프로젝트 단위 | `<프로젝트 루트>\.claude\settings.json` |

전역 설정을 쓰는 경우 아래 **경로 주의사항**을 반드시 확인하세요.

## 수동 병합 예시

아래 블록만 기존 설정에 병합하면 됩니다.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "run": "powershell -NoProfile -ExecutionPolicy Bypass -File .\\hooks\\setup-appid.ps1"
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "run": "powershell -NoProfile -ExecutionPolicy Bypass -File .\\hooks\\notify-stop.ps1"
      }
    ],
    "Notification": [
      {
        "matcher": ".*",
        "run": "powershell -NoProfile -ExecutionPolicy Bypass -File .\\hooks\\notify-user.ps1"
      }
    ]
  }
}
```

## 경로 주의사항

Claude Code 훅은 **`settings.json` 위치가 아닌 Claude가 열린 프로젝트 디렉토리**를 CWD로 사용합니다.

`settings.example.json`의 상대 경로(`.\\hooks\\...`)는 프로젝트 루트 기준이므로,
전역 설정에 넣으면 프로젝트마다 `hooks` 폴더가 있어야 동작합니다.

**방법 A — 절대 경로 사용 (전역 설정 권장)**

```json
"run": "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\Users\\me\\.claude\\hooks\\setup-appid.ps1"
```

`C:\\Users\\me\\.claude\\hooks\\` 부분을 실제 `hooks` 폴더 경로로 바꿔서 사용하세요.

**방법 B — 프로젝트 루트에 hooks 폴더 배치 (프로젝트별 설정)**

```
<프로젝트 루트>/
├── .claude/
│   └── settings.json   ← hooks 블록 병합
└── hooks/              ← 이 레포의 hooks 폴더 복사
    ├── setup-appid.ps1
    ├── notify-stop.ps1
    ├── notify-user.ps1
    └── focus-claude.ps1
```

이 경우 상대 경로 `.\\hooks\\...`를 그대로 사용할 수 있습니다.

## 검증 절차

- ✅ `SessionStart` 실행 후 레지스트리 경로 확인
  - `HKCU\Software\Classes\AppUserModelId\Claude Code`
  - `HKCU\Software\Classes\claude-focus\shell\open\command`
- ✅ `Stop` / `Notification` 실행 시
  - 제목: `[폴더명] Claude Code`
  - 본문: `작업 완료 : ...`
  - 버튼: `화면으로` — 클릭 시 Claude 관련 창 즉시 전면으로 (WindowsTerminal → VSCode → Claude Desktop → PowerShell 순)
- ✅ `Notification` 알림 타입별 접두어
  - `notification_type` 값에 따라 아래 접두어로 매핑

  | notification_type | 토스트 접두어 |
  |-------------------|--------------|
  | `success` | `[완료]` |
  | `info` | `[분석]` |
  | `warning` | `[수정]` |
  | `error` | `[오류]` |
  | 그 외 / 없음 | `[알림]` |

- ✅ `last_assistant_message` 첫 줄이 30자 이내로 잘려 알림에 표시

## 트러블슈팅

- ⚠️ **AUMID 미등록**
  - `hooks/setup-appid.ps1`를 수동 실행한 뒤 레지스트리를 다시 확인하세요.
- 🔕 **알림이 안 뜸**
  - Windows 알림 설정에서 앱 알림 허용 상태를 확인하세요.
- 🌙 **포커스 모드**
  - 집중 지원(포커스 어시스트)이 켜져 있으면 알림이 숨겨질 수 있습니다.
- 🔒 **ExecutionPolicy 오류**
  - `-ExecutionPolicy Bypass`는 해당 실행에만 적용되며 시스템 정책을 영구 변경하지 않습니다.
  - 기업 그룹 정책으로 막혀 있으면 IT 관리자에게 문의하거나, 스크립트 내용을 인라인 명령으로 변환해야 합니다.
- 🐛 **훅 입력값 디버깅**
  - 훅에 실제로 어떤 데이터가 들어오는지 확인하려면 `run` 항목을 아래로 임시 교체하세요:
  ```json
  "run": "powershell -NoProfile -Command \"$input | Out-File $env:TEMP\\claude-hook-debug.json\""
  ```
  - 실행 후 `%TEMP%\claude-hook-debug.json`에서 실제 payload를 확인할 수 있습니다.

## CLAUDE_SNIPPET.md

`CLAUDE_SNIPPET.md`는 Claude에게 응답 첫 줄 형식을 통일하도록 지시하는 최소 스니펫입니다.

이 내용을 Claude Code 프로젝트의 `CLAUDE.md` 또는 전역 `~/.claude/CLAUDE.md`에 복사하면,
`notify-user.ps1`의 `[완료]/[수정]/[분석]/[오류]` 접두어와 일관된 알림 메시지를 받을 수 있습니다.

> 스니펫을 추가하지 않아도 훅은 정상 동작합니다. 알림 본문이 더 읽기 좋아지는 선택적 설정입니다.

## 공유 범위

- 핵심 파일: 6개
- 훅 이벤트: 3개
- 입력 필드: 5개 (Stop 2, Notification 3)
- 상태 태그: 4개
- 설치 방식: 복붙형 (자동 설치 스크립트 없음)
