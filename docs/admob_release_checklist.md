# Smoke Timer AdMob Release Checklist

## Scope

- Monetization model: `AdMob only`
- Excluded on purpose: `인앱결제`, `구독`, `광고 제거 유료 옵션`
- Reason: current project should avoid payment-system work and keep the app legally and operationally simple

## Current Product Policy

- `Home` tab: no banner
- `Record` tab: banner allowed
- `Settings` tab: banner allowed
- Do not add interstitial, rewarded, or app-open ads without a separate UX review

## Required AdMob Setup

### 1. AdMob Console

- Create the app entry in AdMob
- Create one banner ad unit for Android
- Create one banner ad unit for iOS
- Keep test device usage enabled during development

### 2. Build-Time Environment Values

- Android banner ID: `ADMOB_ANDROID_BANNER_ID`
- iOS banner ID: `ADMOB_IOS_BANNER_ID`
- iOS app ID: `ADMOB_IOS_APP_ID`

## Project Configuration Check

### Android

- [android/app/src/main/AndroidManifest.xml](/Users/jaebinchoi/Desktop/smoketimer/smoke_timer/android/app/src/main/AndroidManifest.xml)
  - confirm `com.google.android.gms.ads.APPLICATION_ID` exists
- Release build uses real banner ad unit through `--dart-define`
- Debug build uses Google test ads only

### iOS

- [ios/Runner/Info.plist](/Users/jaebinchoi/Desktop/smoketimer/smoke_timer/ios/Runner/Info.plist)
  - confirm `GADApplicationIdentifier` is wired to `$(ADMOB_IOS_APP_ID)`
- Release build uses real iOS banner ad unit through `--dart-define`
- Debug build uses Google test ads only

## UX Guardrails

- Do not show banner ads on the primary logging flow
- Do not place ads between the timer hero and the main record button
- Do not show ads inside bottom sheets, dialogs, or onboarding
- If banner load fails, collapse the slot instead of showing an error box
- If ads are misconfigured, app must still work without crash or blocking UI

## Privacy / Policy Checklist

- Privacy policy page must mention:
  - ad delivery
  - third-party SDK usage
  - identifiers or diagnostics that may be collected
- Prepare a public privacy policy URL for store listing submission
  - Google Play requires a valid privacy policy URL for apps that collect or handle sensitive user or device data
  - A PDF alone is not sufficient for the store listing requirement
- If consent flow is needed for your traffic, integrate it before release
- Never tap your own real ads on test devices
- Use test ads until store release is ready

## QA Checklist

### Functional

- Launch app with banner IDs missing
  - app still opens
  - ad slot fails safely
- Launch app with test banner IDs
  - banner appears on `Record` and `Settings`
  - banner does not appear on `Home`
- Rotate devices or resize emulator
  - no overflow
  - no clipped navigation

### Release Safety

- Verify release builds are not using Google test ad IDs
- Verify debug builds are not using production ad IDs
- Verify logging does not expose sensitive IDs in release output

## Recommended Release Commands

### Android

```bash
flutter build appbundle \
  --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy
```

### iOS

```bash
flutter build ipa \
  --dart-define=ADMOB_IOS_APP_ID=ca-app-pub-xxxxxxxxxxxxxxxx~zzzzzzzzzz \
  --dart-define=ADMOB_IOS_BANNER_ID=ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy
```

## Rollback Rules

- To remove all banner ads quickly:
  - set `enableBannerAds = false` in [lib/presentation/state/app_config.dart](/Users/jaebinchoi/Desktop/smoketimer/smoke_timer/lib/presentation/state/app_config.dart)
- To restore the old Home banner behavior:
  - set `showBannerOnHomeTab = true` in [lib/presentation/state/app_config.dart](/Users/jaebinchoi/Desktop/smoketimer/smoke_timer/lib/presentation/state/app_config.dart)

## Final Go / No-Go

- Go only if:
  - AdMob IDs are wired correctly
  - privacy policy is ready
  - banner placement passes UX check
  - debug and release ad IDs are separated
  - app is still fully usable when ads fail

- No-Go if:
  - `Home` flow is blocked by ad placement
  - production IDs are tested by manual ad clicking
  - privacy and consent handling is still unresolved
