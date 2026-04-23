# Claude Windows Toast Hooks

> Windows 전용 저장소입니다. (macOS/Linux 미지원)

Claude Code 훅 중 **안정형 3종(SessionStart, Stop, Notification)** 만 분리한 복붙형 레포입니다.
개인 계정/토큰/프로젝트별 민감 설정 없이, 훅 스크립트와 최소 설정 예제만 제공합니다.

## 빠른 시작

1. 이 레포에서 `hooks` 폴더와 `settings.example.json`을 복사해 원하는 위치에 둡니다.
2. `settings.example.json`의 `hooks` 블록을 Claude 설정 파일의 `hooks`에 병합합니다.
3. `SessionStart` 훅이 먼저 실행되어 AUMID(AppUserModelId, Windows 알림 식별자)를 등록하도록 확인합니다.

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

## 검증 절차

- ✅ `SessionStart` 실행 후 레지스트리 경로 확인
  - `HKCU\Software\Classes\AppUserModelId\Claude Code`
- ✅ `Stop` 실행 시
  - 제목: `[폴더명] Claude Code`
  - 본문: `작업 완료 : ...`
- ✅ `Notification` 실행 시
  - `notification_type` 값에 따라 `[완료]/[수정]/[분석]/[오류]` 접두어 매핑
- ✅ `last_assistant_message` 첫 줄이 30자 이내로 잘려 알림에 표시

## 트러블슈팅

- ⚠️ **AUMID 미등록**
  - `hooks/setup-appid.ps1`를 수동 실행한 뒤 레지스트리를 다시 확인하세요.
- 🔕 **알림이 안 뜸**
  - Windows 알림 설정에서 앱 알림 허용 상태를 확인하세요.
- 🌙 **포커스 모드**
  - 집중 지원(포커스 어시스트)이 켜져 있으면 알림이 숨겨질 수 있습니다.

## 공유 범위

- 핵심 파일: 5개
- 훅 이벤트: 3개
- 입력 필드: 5개 (Stop 2, Notification 3)
- 상태 태그: 4개
- 설치 방식: 복붙형 (자동 설치 스크립트 없음)
