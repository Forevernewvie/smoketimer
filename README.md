# Smoke Timer (흡연 타이머)

[![CI](https://github.com/Forevernewvie/smoketimer/actions/workflows/ci.yml/badge.svg)](https://github.com/Forevernewvie/smoketimer/actions/workflows/ci.yml)

흡연 기록을 빠르게 남기고, **마지막 흡연 기준 간격 타이머**와 **로컬 알림**으로 루틴을 관리하는 Flutter 앱입니다.

## Quick Start

### Requirements

- Flutter `3.41.1` (stable) / Dart `3.11.0`
- Android Studio(에뮬레이터) 또는 Xcode(iOS Simulator)

### Run

```bash
flutter pub get
flutter run
```

#### Android Emulator

```bash
flutter emulators
flutter emulators --launch <emulator-id>
flutter devices
flutter run -d <device-id>
```

#### iOS Simulator

```bash
open -a Simulator
flutter devices
flutter run -d <device-id>
```

## 기능 요약 (MVP)

### 플로우

- Splash → (최초 실행) Onboarding → Main
- 최초 실행 여부는 로컬에 영속 저장됩니다.

### 탭 구조 (현재 앱 기준)

- `Home` / `Record` / `Settings`
- 알림 설정은 `Settings` 내부 기능입니다.
  - `Settings`의 **알림 설정** 행
  - `Home` 우측 상단 **벨 아이콘**

### Home

- 마지막 기록 기준 실시간 타이머(원형 링)
  - 남은 시간(간격 내) / 초과 시간(간격 초과) 표시
- `지금 흡연 기록`: 기록 1건 추가(현재 시간, +1개비)
- `되돌리기`: 직전 추가 기록 1건 롤백
- 다음 알림 카운트다운/상태 표시(알림 꺼짐/기록 필요/요일 필요 등)

### Record

- `오늘/주간/월간` 필터
- 요약 카드: 총 개비 / 평균 간격 / 최장 간격
  - 기록이 2개 미만이면 평균/최장은 `-`로 표시
- 기록 리스트: 최근 최대 20건(시간 + 개비 수)

### Settings

- 24시간 표기 토글
- 홈 원형 기준(마지막 흡연 / 오늘 시작)
- 진동, 소리(기본/무음)
- 알림 설정 진입
- 데이터 초기화(기록/설정/온보딩 상태 포함)

### 알림 설정 (Settings 내부)

- 반복 알림 on/off
- 간격(interval): **30분 ~ 4시간**, 5분 단위 선택
- 미리 알림(pre-alert): 0/5/10/15분
- 허용 시간대: RangeSlider(15분 단위), `24:00` 표시 지원(24시간 표기일 때)
- 요일 선택(월~일)
- 알림 권한 요청 / 테스트 알림 보내기
- 화면 내 “다음(미리) 알림” 프리뷰(시간 + 카운트다운)

## 알림 & 권한 (중요)

### 권한 요청 정책

- 앱 실행 시 **권한 팝업을 자동으로 띄우지 않습니다.**
- 권한 요청은 아래 사용자 액션에서만 발생합니다.
  - 반복 알림을 켜는 경우
  - 알림 설정 화면의 `알림 권한`(요청) 탭
  - `테스트 알림 보내기` 탭

### 플랫폼별 권한/설정/수동 QA

- 자세한 내용은 [`docs/notifications.md`](docs/notifications.md)를 참고하세요.
  - Android: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, 부팅 후 재스케줄 등
  - iOS: 권한 거부 시 시스템 설정에서 수동 허용 필요

## 개발/테스트

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
```

## CI (GitHub Actions)

워크플로: [`.github/workflows/ci.yml`](.github/workflows/ci.yml)

- 트리거
  - `pull_request`: `main`
  - `push`: `main`, `codex/**`
  - `workflow_dispatch`: 수동 실행
- Jobs
  - `Analyze & Test` (Ubuntu): `flutter pub get` → format check → `flutter analyze` → `flutter test --coverage`
  - `Build Android (Debug)` (Ubuntu, push 시): `flutter build apk --debug` + APK artifact 업로드
  - `Build iOS (No Codesign)` (macOS, 수동 실행 시): `flutter build ios --no-codesign`

## 프로젝트 구조

`lib/`

- `domain/`: 모델/정책(AppDefaults 등)
- `data/`: SharedPreferences 기반 저장소
- `services/`: 통계/시간 포맷/알림 스케줄러/알림 서비스
- `presentation/state/`: Riverpod 상태(AppController/AppState 등)
- `screens/`: Splash/Onboarding/Main UI
- `widgets/`: 공용 위젯 및 .pen 변환 위젯

`test/`

- `test/features/**`: 피처 단위 유닛/위젯 테스트

## 트러블슈팅

### iOS: CocoaPods 버전 경고

`flutter run` 중 아래와 유사한 경고가 보일 수 있습니다.

- `CocoaPods recommended version 1.16.2 or greater not installed.`

경고가 실제 문제로 이어질 경우 CocoaPods 업데이트 후 다시 시도하세요.

### Android: 정확한 예약 알림(Exact) 제한

Android에서 기기/OS 설정에 따라 정확한 예약이 제한될 수 있습니다.
이 앱은 가능한 경우 exact로 예약하고, 불가능한 경우 inexact로 폴백합니다. 자세한 내용은
[`docs/notifications.md`](docs/notifications.md) 및 `lib/services/notification_service.dart`를 참고하세요.

## License

MIT License. See [`LICENSE`](LICENSE).
