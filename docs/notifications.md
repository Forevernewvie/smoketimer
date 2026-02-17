# Notifications & Permissions (Smoke Timer)

이 문서는 `flutter_local_notifications` + `timezone` 기반 **즉시 알림/예약 알림**이
플랫폼별로 어떤 권한/설정에 영향을 받는지와, **CI/테스트에서 무엇을 검증하고 실제 디바이스에서 무엇을 수동 검증해야 하는지**를 정리합니다.

## 원칙: CI에서 가능한 검증 vs. 디바이스 수동 검증

* CI(GitHub Actions)에서는 OS 레벨의 “실제 알림 수신”을 완전 자동으로 보장할 수 없습니다.
* 대신 CI에서는 다음을 검증합니다.
  * 스케줄 계산 로직(요일/시간대/간격/미리알림 게이트)
  * 설정 변경 시 스케줄 재계산/재등록 경로(AppController -> NotificationService 호출)
  * 포맷/정적 분석/유닛/위젯 테스트 통과
* 실제 디바이스에서는 다음을 수동으로 확인합니다.
  * 권한 허용/거부 케이스에서 즉시 알림이 표시되는지
  * 예약 알림이 허용 시간대/요일에 맞게 오거나, 제한 조건에 의해 다음 슬롯으로 밀리는지
  * (Android) “정확한 알림(Exact)”이 필요한 경우 OS 설정/권한 상태

## Android

### 1) 필요한 퍼미션/Manifest 설정

현재 프로젝트의 매니페스트는 다음을 포함해야 합니다.

* 런타임 알림 권한(API 33+): `android.permission.POST_NOTIFICATIONS`
* 진동(선택): `android.permission.VIBRATE`
* 재부팅 후 재스케줄(예약 알림 유지 목적): `android.permission.RECEIVE_BOOT_COMPLETED`
* 정확한 예약(Exact alarms): `android.permission.SCHEDULE_EXACT_ALARM`
  * Android 14(API 34)부터는 “정확한 알람”이 제한될 수 있으며 사용자 승인/설정이 필요할 수 있습니다.

그리고 예약 알림이 실제로 동작하려면 **Receiver** 2개가 `<application>`에 등록되어야 합니다.

* `com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver`
* `com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver` (BOOT_COMPLETED, MY_PACKAGE_REPLACED 등)

이 등록이 없으면 예약 알림이 트리거되어도 앱이 알림을 표시하지 못합니다.

### 2) 권한/설정 체크 방법(수동 QA)

* Android 13+ (API 33+) 알림 권한:
  * 앱 첫 실행 시 권한 팝업을 “허용”했는지 확인
  * 거부했다면: 시스템 설정 -> 앱 -> Smoke Timer -> 알림 -> 허용
* Android 12+ Exact alarms:
  * 기기마다 UI는 다르지만 일반적으로:
    * 설정 -> 앱 -> “특별한 앱 액세스” -> “알람 및 리마인더(정확한 알람)”에서 앱 허용 여부 확인
  * 허용되지 않은 상태에서도 앱은 **inexact 예약**으로 동작하도록 폴백합니다(정확도가 떨어질 수 있음).
* 배터리 최적화/절전:
  * 제조사/OS 정책에 따라 예약 알림이 지연될 수 있습니다.
  * 테스트 시 절전모드/배터리 최적화를 끄고 비교 검증하세요.

### 3) 즉시/예약 알림 수동 테스트 매트릭스(권장)

아래 항목을 최소 1회씩 수행합니다.

* 즉시 알림
  * Alert 탭 -> “테스트 알림 보내기” -> 즉시 알림 표시 확인
* 예약 알림
  * 반복 ON, interval=30, pre-alert=0, 허용 시간 08:00~24:00, 요일=매일로 설정
  * “지금 흡연 기록”을 눌러 lastSmokingAt 갱신 후, 다음 예약 시간(앱 UI의 next alert 표시)이 기대값인지 확인
  * 허용 시간 밖(예: 02:00)으로 설정하고 next alert가 다음 허용 시작 시각으로 밀리는지 확인
  * 요일에서 오늘을 제외하고 next alert가 다음 유효 요일로 밀리는지 확인

## iOS

### 1) 권한

* iOS는 최초 실행 시 로컬 알림 권한 승인(알림/배지/사운드)이 필요합니다.
* 사용자가 거부하면 앱에서 다시 팝업을 강제로 띄울 수 없으므로:
  * 설정 앱 -> 알림 -> Smoke Timer -> 알림 허용을 켜야 합니다.

### 2) 수동 QA 체크리스트

* “테스트 알림 보내기” 즉시 표시 확인
* 반복 알림 ON 후 일정 예약이 정상적으로 “다음 알림” UI에 반영되는지 확인
* 포그라운드/백그라운드/잠금 화면 상태에서 알림 표시 확인

## Debug 로그 기반 진단(선택)

Debug 빌드에서는 “테스트 알림 보내기” 수행 시 콘솔 로그로 아래 정보를 출력합니다.

* Android: `areNotificationsEnabled`, `canScheduleExactNotifications`, `pendingNotificationRequests` 개수
* timezone local 설정 실패 시 UTC 폴백 여부

CI에서는 이 로그 자체를 검증하지 않고, 스케줄 계산/호출 경로를 테스트로 검증합니다.

