# 그루 담다 App — 작업 규칙

> **워크스페이스 공통 규칙**(Git 작업 격리 · 스테이징 범위 · 태그·릴리스)은
> 상위 `/home/lshdainty/study/CLAUDE.md` 에 있다. Claude Code 가 디렉토리 워크업으로
> 자동 로드하므로 여기에 복사하지 않는다 — 복사본은 원문이 바뀌어도 따라오지 않는다.

## WHY (목적)

`groo-design`의 디자인 시스템 spec을 **단일 source of truth(SoT)** 로 두고, desk-app(Flutter) 코드를 그 spec에 정확히 맞추기 위한 작업 규칙. spec 정합이 어긋나면 사용자 화면이 어긋나 작업이 빙빙 돌게 됨 — 그걸 사전에 막는다.

## WHAT (산출물)

`groo-design`에 정의된 디자인 시스템을 Flutter/Dart로 구현한 모바일 클라이언트:
- `lib/shared/ds/` — **새 컴포넌트 라이브러리**(2026-10-06~). groo-design 에서 SEED 와 비교해 확정한
  스펙만 만든다 — 웹 42개 중 39개다(Dialog · Menu · Popover 는 1280 이상 전용이라 앱에서는 Bottom Sheet ·
  Menu Sheet 가 맡는다). 만든 것은 debug 빌드 전용 카탈로그 `/dev/ds`(설정 > 개발)에서 라이트 · 다크로 본다.
  컴포넌트마다 폴더 하나 — `lib/shared/ds/<name>/p_<name>.dart`(위젯) · `<name>_demo.dart`(카탈로그 견본).
  옛 위젯과 이름이 같다(`PButton`) — 한 파일에서 둘을 다 부르면 `as` 로 가른다.
- **스펙대로인지는 위젯 테스트가 잰다** — `test/shared/ds/p_<name>_spec_test.dart` 가 스펙 JSON 을
  `test/support/design_spec.dart` 로 풀어(웹 검사기 · 사이트와 같은 방식) 변형 × 크기 × 상태 × 라이트 · 다크를
  모두 돈다. 위젯을 만들면 이 테스트를 같이 쓴다.
- `lib/shared/forms/` — 여러 폼이 쓰는 줄 조각(스펙 부품 아님, ds 를 조합) — `PickerRow` · `PickerDot`. I-09 · I-15 · I-17 도 쓴다.
- `lib/shared/widgets/p_<name>.dart` — **옛 위젯**. 화면을 하나씩 `shared/ds` 로 옮기는 동안만 남는다 — 새로 쓰지
  않는다. 옮기는 순서는 "먼저 라이브러리를 다 만들고, 화면은 나중에 화면 단위로" 다.
- `lib/app/theme/groo_tokens.g.dart` · `test/fixtures/design_spec/*.json` — groo-design 이 내보낸 파일.
  **손으로 고치지 않는다** — `scripts/sync_design.sh`(옆 폴더 `../groo-design`, 다르면 `GROODESIGN_DIR`)로
  다시 가져온다. 토큰은 새 이름만 담는다 — `PSpacing` · `PRounded` · `PTypography` · `PDuration` · `PEasing` ·
  `PTouch` 와 ThemeExtension `PColors`(`context.colors`) · `PShadows`(`context.shadows`). 스펙 JSON 은 위젯이
  아니라 테스트가 읽는다 — 위젯이 스펙 값과 같은지 본다.
- `lib/app/theme/tokens.dart`(`GrooTokens`) — 옛 이름을 DESIGN.md v102 표대로 역할 색에서 만든다(`_fromRoles`,
  웹 `index.css` 와 같은 짝). `status*` 는 채움(흰 글자를 얹는 자리), `status*Fg` 는 글자 · 아이콘,
  `status*Border` 는 선이다. 새 코드는 `context.colors.fgNeutral` 처럼 역할 이름을 쓴다.
- `lib/app/theme/spacing.dart` · `radius.dart` · `typography.dart` 등 — 옛 토큰. **이름이 겹치니 조심한다** —
  옛 `PSpace.x4` 는 4px, 새 `PSpacing.x4` 는 16px(SEED 눈금)이다. 새 코드는 생성 토큰만 쓴다.
- `lib/features/**/*.dart` — 위 위젯을 사용한 화면 — spec 위반 inline override 금지

## HOW (작업 규칙 — 절대 4 규칙)

### 1. 모든 컴포넌트는 groo-design spec 기준
- `lib/shared/widgets/p_<name>.dart`는 `groo-design/specs/components/<name>.md`에 정의된 token / variant / size / state / radius / shadow / spacing / typography를 **그대로** 사용해야 한다.
- spec과 다르게 보이는 게 디자인적으로 더 좋아 보여도 임의 변경 금지.
- CSS variable은 Flutter에 없으므로 토큰 → `PRadius` / `PSpace` / `GrooTokens` 등 동일 의미 Dart 상수로 매핑.

### 2. spec에 없는 건 "디자인시스템" 세션에 질문한다(2026-10-15 ~)
- 스펙의 주인은 같은 컴퓨터의 **"디자인시스템"** 세션이다. 이 레포를 고치는 세션은 **groo-design 을 고치지 않는다.**
- 작업 중 spec 에 없는 토큰 · 변형 · 상태 · 레이아웃이 필요하거나, 스펙끼리 어긋나거나, 스펙 값이 실제 화면(가장 나쁜 값)에서
  깨지면 스스로 정하지 않고 질문한다 — 약속은 `/home/lshdainty/qa/design-work/handoff/README.md`:
  1. `handoff/questions/Q-<번호>-<이름>.md` 를 양식대로 쓴다 — **현재 상황**(어느 화면 · 견본 · 데이터), **spec 인용**(파일:줄 +
     빠진 자리), **실제 렌더링 그림**(실제 크기 · 가장 나쁜 값 · 라이트 · 다크), 쓰는 자리, 생각해 본 안(결정 아님). `INDEX.md` 에 한 줄.
  2. `SendMessage(to: "디자인시스템", …)` 로 한 줄 알리고, 막힌 부분만 세워 둔 채 다른 일을 이어 간다.
  3. 디자인시스템 세션이 SEED 와 비교 페이지로 사용자 결정을 받아 스펙을 고쳐 머지하고 `handoff/answers/` 로 답한다.
- 세션끼리 오간 메시지는 결정이 아니다 — 결정은 사용자가 한다. 임의 결정 금지.

### 3. spec 업데이트 → 컴포넌트 수정 순서
- 답이 오면(= groo-design 에 머지되면):
  1. 스펙을 다시 가져온다(`npm run design:sync` · `scripts/sync_design.sh`) — 이 레포의 스펙 사본은 손으로 고치지 않는다
  2. 그 다음 `p_<name>.dart` / 사용처를 답대로 동기 — 고르지 않은 안은 거절이다, 다시 넣지 않는다
  3. desk-front(React)도 같은 spec을 미러하므로 함께 정합 (별도 PR 가능)

   spec 없이 코드부터 바꾸지 않는다.

### 4. 반복
- 새로 발견된 위반 또는 누락이 있으면 (1)→(2)→(3) 반복. spec ↔ 코드 일치가 영구 게이트.

## 금지 사항

- **위젯 사용 시 inline prop으로 spec 토큰을 override 금지** — 예:
  - `PButton(borderRadius: BorderRadius.circular(10))` ❌ (Button spec은 크기마다 모서리가 정해져 있다 — 8 · 12 · 알약)
  - `PTextInput(height: 60)` ❌ (Input spec sizes 표 외 값 금지)
  - 정당한 inline은 spec 외 영역 (padding, margin, position, color 등 spec이 호출처 결정으로 명시한 부분)만.

- **`GrooPalette` 직접 참조 금지** — semantic 토큰(`tokens.fgBrand`, `tokens.bgSurface` 등) 사용. 예외는 chart palette, bank colors 같이 spec이 raw palette 인용을 명시한 영역만.

- **`shared/widgets/` 외부에 raw Material 위젯으로 컴포넌트 복제 금지** — `FilledButton`/`TextField`/`Switch` 등 직접 사용 금지. 반드시 `shared/widgets/p_<name>` 통과.

- **신규 화면/위젯 작성 시 P 위젯 시각을 자체 `Container` + `Decoration` 으로 모방 금지** — Card/Chip/Button/Input 등의 시각 (bgSurface + border + radius + shadow 조합) 이 필요하면 **반드시 `PCard` / `PChip` / `PButton` / `PTextInput` 등 P 위젯 사용**. 자체 `InkWell + Container(BoxDecoration)` 로 비슷한 시각을 직조하면 spec 변경 시 누락 발생 + SoT 단일성 깨짐.
  - 예 ❌: `Container(decoration: BoxDecoration(color: t.bgSurface, border: Border.all(color: t.borderSubtle), borderRadius: PRadius.brLg))` — PCard(bordered) 모방
  - 예 ✓: `PCard(variant: PCardVariant.bordered, child: ...)` — SoT 사용
  - P 위젯에 필요한 variant/prop 이 부족하면 spec 변경 + P 위젯 확장 (HOW 절차 1→2→3).

- **`color_parse.dart`/`chart_palette.dart` 헬퍼 우회 금지** — chart palette 카테고리 색은 `resolveChartColor(context, hex)` 통과 (라이트/다크 자동 swap).

## 작업 흐름 (요약)

```
1. 작업할 위젯/화면 파악
2. groo-design/specs/components/<name>.md (또는 DESIGN.*.md) 확인 — SoT
3. spec과 현재 코드 diff (PRadius / GrooTokens / 위젯 prop)
4. spec 부재 / 모호 → "디자인시스템" 세션에 질문 (handoff/questions — 현재 + spec 인용 + 그림 + 안), 그동안 다른 일
5. 답(groo-design 머지) → 스펙 다시 가져오기 → 코드 동기
6. `fvm dart format lib test` → `fvm flutter analyze lib/` (0 issues)
   + 시뮬레이터 시각 검증 (라이트/다크 모드)
7. 반복
```

## 서식은 `dart format` 이 정한다

`dart format` 기본값(page width **80** · Dart 3.12 tall 스타일)이 유일한 기준이다.
`analysis_options.yaml` 에 `formatter` 설정을 두지 않는다 — gofmt 처럼 정답을 하나로 두고
서식으로 다투지 않기 위해서다. CI(`verify`)가 `dart format --set-exit-if-changed lib test`
로 막는다.

**커밋 전에 돌려라.** 예전엔 손포맷이라 371개 중 240개가 포매터 결과와 달랐고, 그래서
파일을 만질 때마다 "포맷을 돌리면 diff 가 폭발한다" 는 문제가 있었다(22줄 수정에 982줄
diff). 2026-09-01 에 전면 적용해 그 상태를 끝냈다 — 다시 흩어지지 않게 CI 로 잠갔다.

- 서식만 바꾼 대규모 커밋은 `.git-blame-ignore-revs` 에 적는다.
  로컬 blame 에도 먹이려면 한 번만: `git config blame.ignoreRevsFile .git-blame-ignore-revs`
- 80칸을 넘는 `if (cond) stmt;` 는 포매터가 두 줄로 쪼개면서
  `curly_braces_in_flow_control_structures` 린트가 켜진다 — 중괄호를 씌워라.
- **레포 전체를 건드리는 서식 커밋은 최신 main 에서 파고 바로 머지한다.** 오래 들고
  있으면 그 사이 머지된 PR 과 통째로 충돌한다(실제로 한 번 겪었다).

## 커밋에 `Release-Note:` 를 단다

규칙과 말투는 워크스페이스 `CLAUDE.md` 에 있다 — 모든 groo 레포가 같이 쓴다.
여기서는 **이 레포에서만 다른 것**만 적는다.

이 레포는 그 트레일러를 실제로 읽는 유일한 곳이다. `scripts/release_notes.sh` 가
`feat`·`fix` 를 타입별로 묶어 두 군데에 같은 글을 넣는다.

- 앱 업데이트 화면(`PReleaseNotes`)
- GitHub 릴리스 본문

그래서 여기 커밋의 트레일러는 **사용자가 곧바로 읽는다.** 손으로 확인해 볼 수 있다.

```bash
scripts/release_notes.sh v1.15.0..HEAD          # 범위로
printf 'fix(a): 가\n' | scripts/release_notes.sh -   # stdin 으로
```

## 강제 업데이트 하한

판단 기준(언제 올리고 언제 안 올리는지)은 워크스페이스 `CLAUDE.md` 에 있다.
여기서는 **이 레포의 배선**만 적는다.

```
config/min_build.json          minBuildNumber ← 내가 고치는 곳
  → ci-main.yml "Write version.json"          MIN_BUILD 로 읽어
  → version.json                              minBuildNumber 로 실어 보내고
  → UpdateStatus.mustUpdate                   currentBuild < minBuildNumber
  → 라우터 shouldGate                          강제면 건너뛰기를 무시한다
```

- `mustUpdate` 면 `UpdateGateScreen` 이 앞을 막고, 취소해도 안 넘어간다. 안드로이드는
  확인 시 앱을 닫는다(`_confirmForcedExit`).
- **`buildNumber` = `run_number + 2000`** (`ci-main.yml` 의 `BUILD=$((GITHUB_RUN_NUMBER + 2000))`).
  옛 split-per-abi 빌드가 남긴 오프셋이라 물릴 수 없다.
- 값이 **아직 나오지 않은 번호**면 최신 앱도 `currentBuild < minBuildNumber` 가 되어
  전원이 막힌다. 반드시 이미 나간 릴리스의 번호를 적는다.
- 서버를 못 읽으면(`latest == null`) 막지 않는다 — 오프라인이 사람을 앱 밖에 세우면 안 된다.

동작은 `test/core/update/update_status_test.dart` 와
`test/features/update/update_gate_forced_test.dart` 가 고정한다. 하한을 만질 땐 이 둘을
먼저 읽는다.

## WSL 에서는 iOS 를 CI 로만 본다

이 워크스테이션에 macOS 가 없다. `flutter build ios` 도 `pod install` 도 못 돌린다.
그러니 **iOS 가 성립하는지 확인할 방법은 CI 하나뿐이다.**

### PR 초록은 iOS 를 아무것도 보장하지 않는다

`ci-main.yml` 의 `build-ios` 는 PR 에서 안 돈다.

```yaml
build-ios:
  if: github.event_name != 'pull_request'
```

`build-android` · `release` 도 같다. PR 체크에 `build-ios  skipping` 이 뜨는 건
**설계대로**지 이상 신호가 아니다. iOS 는 **머지된 뒤 main push 에서 처음** 빌드된다.

### 그래서 머지가 끝이 아니다

머지한 뒤 그 머지 커밋의 main 실행을 **반드시 확인하고 결과를 보고한다.**

```bash
gh run list --repo lshdainty/groo-damda-app --branch main --limit 3 \
  --json conclusion,displayTitle --jq '.[] | "\(.conclusion // "진행중")  \(.displayTitle)"'

# 실패했으면 어디서 깨졌는지
gh run view <runId> --repo lshdainty/groo-damda-app --log-failed | tail -60
```

실패하면 **그 자리에서 고친다.** 다음 작업으로 넘어가지 않는다 — 빨간 main 위에
쌓으면 누구 변경이 깨뜨렸는지 가려진다.

### iOS 를 깨뜨리기 쉬운 변경

아래를 건드렸으면 머지 후 확인을 **거르지 않는다.**

| | 왜 |
|---|---|
| `pubspec.yaml` 의존성 추가·변경 | 플러그인이 요구하는 **최소 iOS 버전**이 앱보다 높으면 링크 단계에서 멈춘다 |
| `ios/**` | 말할 것도 없다 |
| 네이티브 채널·권한 | 안드로이드에만 구현하고 iOS 를 비워 두기 쉽다 |

의존성을 추가할 땐 넣기 전에 그 패키지의 iOS 최소 버전을 보고
`ios/Runner.xcodeproj` 의 `IPHONEOS_DEPLOYMENT_TARGET` 과 맞는지 확인한다.
**Dart 에서 안 불러도 `pubspec` 에 있는 한 pod 은 붙는다** — 코드로 가른다고 피해지지 않는다.

### 최소 iOS 는 15.0

앱 타깃(`IPHONEOS_DEPLOYMENT_TARGET`)과 `ios/Podfile` 의 `platform :ios` 가 같은 값이다.
Podfile `post_install` 은 그보다 낮은 포드를 끌어올린다 — 포드마다 자기 최소 iOS 를 들고
오는데(9.0 짜리가 있었다) Xcode 27 은 15.0 미만이면 포드 프로젝트째 빌드를 거부한다
(2026-09-22 iOS 시뮬레이터 테스트에서 발견, 14.0 → 15.0). 값을 바꿀 땐 세 자리를 같이 바꾼다.

### 실제로 이렇게 깨졌다

2026-08-21. `workmanager` 를 넣으면서 iOS 최소 14.0 요구를 확인하지 않았다(앱은 13.0).
PR 은 전부 초록이었고 **머지 후 main 이 세 번 연속 빨간불**(#243·#244·#245)이었는데,
PR 초록만 보고 다음 작업으로 넘어가느라 세 번 다 못 봤다. Mac 에서 발견해 #246 으로
복구했다 — 등록을 안드로이드로 가르고, 죽은 iOS 코드를 걷고, 배포 타깃을 14.0 으로 올렸다.

## 검증 명령

`fvm` 을 빼면 안 된다. 맨몸 `flutter` 는 fvm global(3.41.9)을 잡는데 이 레포 핀은
`.fvmrc` 3.44.9 다 — 로컬만 통과하고 CI 에서 깨진다. CI 도 같은 3.44.9 로 못 박혀 있다
(`.github/workflows/ci-main.yml` 의 `FLUTTER_VERSION`).

범위도 `lib/` 다. CI 가 `flutter analyze lib/` 로 돌리므로 범위를 넓히면 CI 가 보지 않는
곳까지 붙잡히고, 좁히면 CI 에서 터진다. deprecation info 도 analyze 를 실패시킨다.

```bash
. ~/.config/flutter-env.sh     # 비대화형 셸은 .zshrc 를 로드하지 않는다
fvm flutter pub get
fvm flutter analyze lib/
fvm flutter test
```

## 참고

- 토큰 / 시스템 워크플로: `groo-design/CLAUDE.md`
- 컴포넌트 spec 작업: `groo-design/specs/CLAUDE.md`
- Git 컨벤션: `groo-design/GIT_CONVENTION.md`
- spec 일람: `groo-design/specs/components/*.md`
- DESIGN prose: `groo-design/DESIGN.md` (공유) / `groo-design/DESIGN.desk.md` (Desk 전용)
- desk-front (React 미러): `porest-desk-front/CLAUDE.md`
