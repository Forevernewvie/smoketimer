# Smoke Timer (흡연 타이머)

[![CI](https://github.com/Forevernewvie/smoketimer/actions/workflows/ci.yml/badge.svg)](https://github.com/Forevernewvie/smoketimer/actions/workflows/ci.yml)

흡연 기록을 빠르게 남기고, 마지막 기록 기준 타이머와 로컬 알림으로 루틴을 관리하는 Flutter 앱입니다.

## 핵심 기능

- 3탭 구조: `Home` / `Record` / `Settings`
- 실시간 원형 타이머 + 빠른 기록/되돌리기
- 알림 스케줄(반복, 간격, 미리 알림, 요일, 허용 시간대)
- 비용 설정 기반 지출 요약
- 다크모드 토글(영속 저장)
- `ko/en` 로컬라이제이션(현재 다크모드/설정 핵심 라벨 반영)

## 최근 반영 사항

- 다크모드 설정 추가 및 재시작 후 유지
- 다크모드 관련 UI 문구 로컬라이즈
  - `다크 모드` / `Dark Mode`
  - `설정` / `Settings`
- 알림 설정의 `미리 알림` UX 개선
  - 기존 단계형(0/5/10/15) 순환 방식 → `0~15분` 슬라이더
- 다크모드/반응형/접근성 테스트 보강

## 앱 플로우

- Splash → (최초 실행) Onboarding → Main
- 온보딩 완료 여부는 로컬 저장소에 영속 저장

## 화면별 동작

### Home

- 마지막 기록 기준 원형 타이머
- `지금 흡연 기록`: 기록 1건 추가
- `되돌리기`: 직전 기록 롤백
- 다음 알림 상태/카운트다운 표시

### Record

- 필터: `오늘` / `주간` / `월간`
- 요약: 총 개비, 평균 간격, 최장 간격
- 최근 기록 리스트 표시

### Settings

- 알림 설정 진입
- 비용 설정(갑당 가격, 한 갑 개비 수, 통화)
- 24시간 표기
- 다크 모드
- 홈 원형 기준
- 진동/소리
- 데이터 초기화

### Alert Settings (Settings 내부)

- 반복 알림 on/off
- 간격: 30분~4시간
- 미리 알림: 0~15분 슬라이더
- 허용 시간대(RangeSlider)
- 요일 선택(월~일)
- 권한 요청, 테스트 알림 보내기

## 로컬라이제이션

- 지원 locale: `ko`, `en`
- 앱 locale이 `ko`면 한국어, `en`이면 영어 표시
- 지원하지 않는 locale은 `ko`로 fallback
- 번역 키 누락 시 키 문자열 반환으로 안전 fallback

## 기술 스택

- Flutter / Dart
- Riverpod (상태관리)
- SharedPreferences (로컬 저장)
- flutter_local_notifications (알림)
- google_mobile_ads (광고)

## 개발 환경

- Flutter `3.41.1`
- Dart `3.11.0`
- Android Studio Emulator 또는 iOS Simulator

## 실행

```bash
flutter pub get
flutter run
```

### Android Emulator

```bash
flutter emulators
flutter emulators --launch <emulator-id>
flutter devices
flutter run -d <device-id>
```

### iOS Simulator

```bash
open -a Simulator
flutter devices
flutter run -d <device-id>
```

## 테스트 / 품질

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

검증 포인트:
- 기능/플로우/데이터 로직 회귀 없음
- 다크모드 토글 즉시 반영 + 영속성
- `ko/en` 로컬라이제이션 표시 검증
- 반응형/접근성 텍스트 스케일에서 overflow/clipping 방지

## CI

워크플로: `.github/workflows/ci.yml`

- `pull_request` to `main`
- `push` to `main`, `codex/**`
- 분석/테스트 + Android 빌드 + (수동) iOS 빌드

## 디렉터리 구조

- `lib/domain`: 모델/정책
- `lib/data`: 저장소
- `lib/services`: 스케줄러/포맷터/알림/통계
- `lib/presentation/state`: Riverpod 상태
- `lib/screens`: 앱 화면
- `lib/widgets`: 공용 위젯
- `test/features`: 기능 단위 테스트

## 참고 문서

- 알림 정책/플랫폼 이슈: `docs/notifications.md`

## License

MIT. See `LICENSE`.
