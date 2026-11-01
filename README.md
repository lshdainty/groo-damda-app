<p align="center">
  <img src="https://img.shields.io/badge/%EA%B7%B8%EB%A3%A8_%EB%8B%B4%EB%8B%A4-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="그루 담다" />
</p>

<h1 align="center">그루 담다 App</h1>

<p align="center">
  <strong>개인 생산성/라이프 로그 관리를 위한 Desk 모바일 앱 (iOS + Android)</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Riverpod-3-45A2F5" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android-555555" alt="Platform" />
</p>

---

## 소개

**그루 담다 App**은 [그루](https://github.com/lshdainty/groo) 서비스의 Desk 모바일 앱입니다.

가계부(지출/수입), 할 일, 캘린더, 메모, 자산, 통계 등 생산성 기능을 Flutter 기반 iOS/Android 앱으로 제공합니다.

Flutter SDK 버전은 [FVM](https://fvm.app)으로 고정합니다(`.fvmrc` = 3.44.9, CI 와 동일한 값). 모든 커맨드는 `fvm flutter ...` 로 실행합니다.

---

## 기술 스택

| Category | Technology |
|----------|------------|
| **Language** | ![Dart](https://img.shields.io/badge/Dart_3.11-0175C2?style=flat-square&logo=dart&logoColor=white) |
| **Framework** | ![Flutter](https://img.shields.io/badge/Flutter_3.44.9_(FVM)-02569B?style=flat-square&logo=flutter&logoColor=white) |
| **State Management** | ![Riverpod](https://img.shields.io/badge/flutter__riverpod_3-45A2F5?style=flat-square) ![riverpod_generator](https://img.shields.io/badge/riverpod__annotation%2Fgenerator-45A2F5?style=flat-square) |
| **Routing** | ![go_router](https://img.shields.io/badge/go__router_17-02569B?style=flat-square) |
| **HTTP / Auth** | ![dio](https://img.shields.io/badge/dio_5-1B7FBD?style=flat-square) ![cookie](https://img.shields.io/badge/cookie__jar%2Fdio__cookie__manager-1B7FBD?style=flat-square) ![inappwebview](https://img.shields.io/badge/flutter__inappwebview_(SSO_OAuth2%2BPKCE)-34353F?style=flat-square) ![secure_storage](https://img.shields.io/badge/flutter__secure__storage-34353F?style=flat-square) |
| **Model / Codegen** | ![freezed](https://img.shields.io/badge/freezed-3E67B1?style=flat-square) ![json_serializable](https://img.shields.io/badge/json__serializable-3E67B1?style=flat-square) ![build_runner](https://img.shields.io/badge/build__runner-3E67B1?style=flat-square) |
| **i18n** | ![gen-l10n](https://img.shields.io/badge/flutter__localizations%2Fintl%2Fgen--l10n-26A69A?style=flat-square) |
| **Chart / Calendar** | ![fl_chart](https://img.shields.io/badge/fl__chart-22B5BF?style=flat-square) ![table_calendar](https://img.shields.io/badge/table__calendar-22B5BF?style=flat-square) |
| **Icons / Fonts** | ![lucide](https://img.shields.io/badge/lucide__icons__flutter-EF4444?style=flat-square) ![fonts](https://img.shields.io/badge/Pretendard%2FJetBrains_Mono_(내장)-555555?style=flat-square) |
| **Device / Etc** | ![pickers](https://img.shields.io/badge/file__picker%2Fimage__picker%2Fshare__plus-8B5CF6?style=flat-square) ![etc](https://img.shields.io/badge/connectivity__plus%2Fshared__preferences%2Flogger-8B5CF6?style=flat-square) |

---

## 프로젝트 구조

```text
lib/
├── app/                 # 앱 초기화(app.dart), 환경변수(env.dart), 라우터, 테마 토큰
├── core/                # 공통 인프라 — auth, network, format, settings, storage, sync
├── features/            # 기능 단위 화면/상태 (expense, todo, calendar 등)
├── shared/              # 공용 P 위젯(widgets), icons, brand, responsive
├── l10n/                # 다국어 ARB + generated/ (gen-l10n 산출물, 커밋됨)
└── main.dart            # 엔트리포인트

config/                  # 환경별 dart-define JSON (local / dev / prod)
assets/                  # 폰트(Pretendard, JetBrains Mono), data/krx_stocks.json
```

---

## 시작하기

### 요구사항

- **FVM**: `brew tap leoafarias/fvm && brew install fvm`
- **Flutter SDK**: `fvm install` (`.fvmrc`에 핀된 stable 채널 자동 사용)

### 설치 및 실행

```bash
# 의존성 설치
fvm flutter pub get

# 실행 (dev 서버)
fvm flutter run --dart-define-from-file=config/dev.json

# 다국어 파일 생성 (lib/l10n/generated)
fvm flutter gen-l10n

# 코드 생성 (freezed / json_serializable / riverpod_generator)
fvm dart run build_runner build --delete-conflicting-outputs

# 정적 분석
fvm flutter analyze

# 릴리즈 APK 빌드
fvm flutter build apk --release --dart-define-from-file=config/dev.json
```

### 환경 변수 (config/*.json)

환경별 설정은 `config/local.json` · `config/dev.json` · `config/prod.json`에 모아두고
`--dart-define-from-file`로 한 번에 주입합니다. (미지정 시 `lib/app/env.dart` 기본값 = **dev**)

| 키 | 설명 |
|---|---|
| `APP_ENV` | 환경 식별자 (local \| dev \| prod) |
| `API_BASE` | Desk 백엔드 base URL (dio가 뒤에 `/api/v1` 부착) |
| `SSO_URL` | SSO **프론트**(React 로그인 페이지) base URL — SSO 백엔드 아님 |
| `WEB_BASE_URL` | desk-front(React 웹) base URL — 차트 WebView 임베드 페이지 origin |

```bash
fvm flutter run                 --dart-define-from-file=config/local.json   # 로컬 도커
fvm flutter run                 --dart-define-from-file=config/dev.json     # dev (기본)
fvm flutter build apk --release --dart-define-from-file=config/prod.json    # prod
```

- **로컬 도커**(`config/local.json`)는 `http://localhost:8002`. 단 실기기는 localhost=폰 자신이라 못 닿으니
  PC LAN IP(예: `http://192.168.0.x:8002`), Android 에뮬레이터는 `http://10.0.2.2:8002`로 바꿔 씁니다.
- **dev**: `https://damda-dev.hangroo.io` / SSO `https://sso-dev.hangroo.io`
- **prod**: `https://desk.porest.cloud` / SSO `https://sso.porest.cloud`

### 다국어 (i18n)

- ARB 소스: `lib/l10n/app_ko.arb`(템플릿) · `lib/l10n/app_en.arb`
- 설정: `l10n.yaml` (output `lib/l10n/generated/`, 클래스 `AppLocalizations`)
- 생성물은 커밋되며, `pubspec.yaml`의 `generate: true`로 `pub get` 시에도 자동 생성됩니다.

---

## 주요 화면 (lib/features/)

- `dashboard` — 홈 대시보드
- `expense` · `expense_split` · `recurring` · `subscription` — 지출/수입, 분할, 반복, 구독
- `budget` · `category` · `card` · `preset` — 예산, 카테고리, 카드, 프리셋
- `asset` · `stocks` · `saving_goal` — 자산, 주식(토스 연동), 저축 목표
- `todo` · `constellation` — 할 일, 별자리 게이미피케이션
- `calendar` · `memo` — 캘린더, 메모
- `stats` · `search` — 통계, 검색
- `import` · `export` · `file` — 데이터 가져오기/내보내기, 파일
- `dutch_pay` — 더치페이
- `auth` · `settings` · `notification` · `more` — 로그인(SSO), 설정, 알림, 더보기

---

## 관련 저장소

| Repository | Description |
|------------|-------------|
| [그루](https://github.com/lshdainty/groo) | 통합 레포지토리 (서비스 소개) |
| [porest-desk-back](https://github.com/lshdainty/porest-desk-back) | Desk 백엔드 (REST API) |
| [porest-desk-front](https://github.com/lshdainty/porest-desk-front) | Desk 웹 프론트엔드 |
| [groo-core](https://github.com/lshdainty/groo-core) | 공통 라이브러리 |
| [porest-sso-back](https://github.com/lshdainty/porest-sso-back) | SSO 백엔드 |
| [porest-sso-front](https://github.com/lshdainty/porest-sso-front) | SSO 프론트엔드 |

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/lshdainty">lshdainty</a>
</p>
