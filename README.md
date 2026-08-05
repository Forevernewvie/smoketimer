# 📱 Smoke Timer (Warm Ritual Timer) - React Native Expo

Smoke Timer는 강박적인 단번에 끊기 대신, **자신의 흡연 간격 리듬과 지출 금액을 객관적으로 관찰**함으로써 자연스러운 흡연 조율을 돕는 **Warm Ritual Timer** 모바일 애플리케이션입니다.

---

## 🎨 핵심 디자인 & 제품 철학

- **Warm Neutral & Minimal**: 아이보리 베이스 (`#F6F4EF`), 차분한 그래파이트 (`#202124`), 앰버 토바코 포인트 (`#D88A2D`)
- **비심판적 어조 (Non-judgmental Tone)**: 죄책감을 주는 팝업이나 게이미케이션을 배제하고 실시간 경과 시간과 지출 금액을 있는 그대로 제시
- **되돌리기 (Soft Relapse Undo)**: 실수로 기록을 남겼을 때 원터치 롤백 가능
- **100% 온디바이스 개인정보 보호**: 회원가입/서버 수집 0%, `@react-native-async-storage/async-storage` 기반 기기 내부 저장

---

## 🛠️ 기술 스택 (Tech Stack)

- **Framework**: React Native 0.86 (Expo SDK 57 / Expo Router v4)
- **Language**: TypeScript (Zero Error Strict Mode)
- **Navigation**: Expo Router (File-based Routing)
- **State Management**: React Context (`AppStateContext`) + AsyncStorage Persistence
- **Haptics**: `expo-haptics` (iOS / Android / Web Safe-guarded)
- **Graphics**: `react-native-svg` (Circular Hero Timer Arc Gauge)

---

## 🚀 시작하기 (Getting Started)

```bash
# 1. 의존성 패키지 설치
npm install

# 2. 로컬 개발 서버 구동 (Web)
npm run web

# 3. iOS 시뮬레이터 구동
npm run ios

# 4. 안드로이드 에뮬레이터 구동
npm run android
```

---

## ⚙️ CI/CD 파이프라인 (GitHub Actions)

- **`CI (ci.yml)`**: Node.js 20 환경에서 `npx tsc --noEmit` 타입 검수, ESLint 린트 검수 및 `npx expo export --platform web` 빌드 자동 수행
- **`Privacy Policy Pages (privacy-policy-pages.yml)`**: `site/` 디렉터리의 개인정보 처리방침을 GitHub Pages로 자동 배포
