# UI/UX Visual Audit Checklist

반복 점검 시 아래 순서대로 확인한다.

## 1. 정적 검증

- [ ] `flutter analyze` 실행
- [ ] 반응형 테스트 실행
- [ ] 다크 모드 안정성 테스트 실행
- [ ] 온보딩 정렬 테스트 실행
- [ ] 광고 배너가 포함된 화면 테스트 실행

권장 명령:

```bash
flutter analyze
flutter test test/features/navigation/ui_stability_matrix_test.dart
flutter test test/features/navigation/dark_mode_ui_stability_matrix_test.dart
flutter test test/features/navigation/foldable_responsive_test.dart
flutter test test/features/navigation/galaxy_responsive_audit_test.dart
flutter test test/features/navigation/tabs_responsive_test.dart
flutter test test/features/onboarding/onboarding_alignment_test.dart
flutter test test/features/ads/banner_slot_widget_test.dart
```

## 2. 실제 기기 또는 에뮬레이터 점검

- [ ] Android 에뮬레이터 연결 확인
- [ ] 디버그 APK 빌드
- [ ] 앱 설치 후 실행
- [ ] Home 기본 상태 캡처
- [ ] Home 스크롤 상태 캡처
- [ ] Record 기본 상태 캡처
- [ ] Settings 주요 섹션 캡처
- [ ] Onboarding 1장 이상 캡처

권장 명령:

```bash
flutter devices
flutter build apk --debug
"$HOME/Library/Android/sdk/platform-tools/adb" -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
"$HOME/Library/Android/sdk/platform-tools/adb" -s emulator-5554 shell monkey -p com.forevernewvie.smoketimer -c android.intent.category.LAUNCHER 1
```

## 3. 화면별 점검 포인트

### Home

- [ ] 타이머 히어로 영역이 첫 화면에서 잘리지 않는가
- [ ] 상태 카드 라벨과 상태 칩이 같은 축에서 정렬되는가
- [ ] `지금 흡연 기록` CTA가 광고와 하단바에 묻히지 않는가
- [ ] `되돌리기` 버튼이 비활성/활성 상태에서 흔들리지 않는가
- [ ] 광고 배너가 붙어도 콘텐츠 간격이 과도하게 압축되지 않는가

### Record

- [ ] 기간 필터가 같은 폭과 같은 기준선으로 보이는가
- [ ] `총 개비`, `평균 간격`, `최장 간격` 카드 폭이 좁은 화면에서 줄어들지 않는가
- [ ] 빈 상태 문구와 CTA가 어색하게 붙거나 잘리지 않는가
- [ ] 기록 리스트 셀의 시간/본문 위계가 깨지지 않는가

### Settings

- [ ] 섹션 간 간격이 일정한가
- [ ] 토글, trailing 값, 설명 문구가 세로 정렬에서 흔들리지 않는가
- [ ] 위험 액션 섹션이 분리되지만 과도하게 튀지 않는가

### Onboarding

- [ ] 상단 스킵, 본문, 하단 CTA가 safe area 안에 있는가
- [ ] 제목과 설명 줄 수가 달라도 전체 정렬이 안정적인가
- [ ] 페이지 인디케이터와 CTA 간격이 일관적인가

## 4. 깨짐 판정 기준

- [ ] 텍스트 overflow, clipped text, 잘린 아이콘이 없는가
- [ ] 카드 폭이 intrinsic size 때문에 줄어들지 않는가
- [ ] `Expanded`, `Flexible`, `double.infinity` 사용이 무한 높이 제약을 만들지 않는가
- [ ] 동일한 역할의 컴포넌트가 다른 화면 너비에서 다른 정렬 규칙을 보이지 않는가
- [ ] 다크 모드에서 대비가 붕괴하지 않는가
- [ ] 가로 모드에서 CTA 또는 핵심 정보가 화면 밖으로 밀리지 않는가

## 5. 수정 후 재검증

- [ ] `dart format` 실행
- [ ] 수정한 화면 관련 테스트 재실행
- [ ] 실제 캡처 다시 확인
- [ ] 변경 파일과 결과를 간단히 기록

## 6. 보고 형식

- 문제였던 지점
- 수정한 파일
- 실행한 테스트
- 실제 캡처 확인 결과
- 남은 리스크

