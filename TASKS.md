# porest-desk-app 잔여 작업 리스트

> Claude Code 세션에서 추적 중인 task. 다른 컴퓨터에서 작업 이어갈 때 이 파일 보고 ID 기준으로 진행.
> 완료한 항목은 체크박스 켜고 commit 메시지에 task ID 적기 (예: `feat: ... (#114)`).

## 진행 가이드
- **참조 자료 (front)**: `git clone https://github.com/lshdainty/groo-damda-front.git` 후 `src/` 참조 — Claude Code on the Web 컨테이너에서도 git clone 가능
- **참조 자료 (back)**: `git clone https://github.com/lshdainty/groo-damda-back.git` — API/스케줄러 시그니처 확인용
- **캡쳐 PNG**: `/tmp/groo-screens/` (필요 시 `python3 scripts/capture_screens.py`, porest-desk-front `localhost:3002` 띄운 상태)
- **백엔드 실행/DB 수정은 사용자가 직접** — 코드 수정만 자동
- **mock·임시 구현 금지** — API 있으면 무조건 연결
- **N+1 쿼리 사전 점검** — 집계/추이 API 추가 시
- **컨테이너 push 권한 이슈**: GitHub App 의 Contents:write 권한 + 레포 설치 필요. 권한 풀리기 전엔 commit 만 누적, push 는 권한 부여 후 일괄.

---

## 우선순위 1 — 작은 수정 (1~2시간 이내)

- [x] **#125 TRANSFER(이체) 옵션 재추가** (commit `55d2146`)
  - `add_tx_sheet.dart` `_TypeSegment._opts` 에 `('TRANSFER','이체')` 추가
  - TRANSFER 선택 시 카테고리/가맹점/결제수단 섹션 숨김, 보낼/받을 자산 picker + 수수료
  - 제출 시 `assetRepo.createTransfer()` 분기 호출, 편집 모드선 옵션 숨김
  - **잔여**: `preset_edit_dialog.dart`, `recurring_edit_dialog.dart` 에 TRANSFER 옵션 추가는 백엔드 시맨틱 확인 후 별도 처리

- [ ] **#129 캡쳐 실패 모달 selector 수정 후 재캡쳐** (BLOCKED — 컨테이너에 브라우저 없음)
  - `scripts/capture_modals.py` 의 M02-M05, M07-M09 selector 들이 부정확
  - 실패 항목: M02 자산추가, M03 자산상세, M04 예산설정, M05 거래상세, M07 메모추가, M08 할일추가, M09 더치페이추가
  - 로컬 PC 에서 직접 처리 필요

- [x] **#131 HideAmountsUnlockDialog 구현 — 금액 숨김 잠금해제** (commit `ba20640`)
  - `core/auth/auth_repository.dart` 에 `verifyPassword(password)` 추가 (POST `/users/me/verify-password`)
  - `core/settings/settings_notifier.dart` 에 `setHideAmounts(bool)` 추가
  - `core/settings/hide_amounts_unlock_dialog.dart` 신규 — 잠금 해제(true→false) 시 비밀번호 검증
  - `mobile_header.dart` / `asset_screen.dart` 토글 호출부 → `toggleHideAmountsWithUnlock` 으로 교체

---

## 우선순위 2 — 화면 디자인 미러 (각 화면당 1~3시간)

> 기존 화면들은 이미 동작 가능한 상태로 구현돼 있음. 픽셀 미러 폴리시는 캡쳐 PNG 검증이 필요해 컨테이너에서 진행 어려움. 로컬 PC 에서 화면 띄워보면서 진행 권장.

- [ ] **#114 Expense 화면 미러** — `02-expense.png`
  - `lib/features/expense/presentation/expense_screen.dart`
  - 헤더 m-header 포맷, 월간 요약 카드, 일자별 그룹핑된 거래 리스트, FAB 추가 버튼
- [ ] **#115 Stats 화면 미러** — `03-stats.png`
- [ ] **#116 More 화면 미러** — `04-more.png`
- [ ] **#117 Budget 화면 미러** — `06-budget.png`
- [ ] **#118 Calendar 화면 미러** — `07-calendar.png`
- [ ] **#119 Todo 화면 미러** — `08-todo.png`
- [ ] **#120 DutchPay 화면 미러** — `09-dutch-pay.png`
- [ ] **#121 Memo 화면 미러** — `10-memo.png`
- [ ] **#122 Group 화면 미러** — `11-group.png` (#139 상세 화면은 이미 구현됨 — 리스트 컴포넌트 폴리시만 남음)
- [ ] **#123 Card-Settings 화면 미러** — `12-card-settings.png`
- [x] **#124 Settings 화면 미러** — `13-settings.png` (commit `6b89258`, #136 와 통합 처리)
  - 9개 섹션 그룹핑, 카테고리/계좌·카드/예산/반복/프리셋/알림 → 기존 라우트로 push
  - 표시 설정: AppearanceSection inline
  - 데이터 내보내기: showExportDialog
  - 계정 섹션: 사용자 정보 + 로그아웃

---

## 우선순위 3 — 모달 디자인 미러

> 픽셀 미러 폴리시는 캡쳐 검증이 필요. 기능적으로는 이미 동작.

- [ ] **#126 AddTxSheet 모달 미러** — `M01-add-tx.png` (#125 TRANSFER 분기는 이미 구현됨)
- [ ] **#127 EventAdd 모달 미러** — `M06-event-add.png`
- [ ] **#128 GroupAdd 모달 미러** — `M10-group-add.png`
- [ ] **#129 의 모달들** — selector 수정 후 (#129 BLOCKED)

---

## 우선순위 4 — 빠진 기능 추가

- [x] **#132 거래→더치페이/반복거래 변환 다이얼로그** (commit `47c3342`)
  - `tx_detail_dialog.dart` 에 "더치페이로" 버튼 추가
  - `DutchPayCreateDialog(fromExpense:)` — title/금액/날짜 미리채움 + sourceExpenseRowId 전달
  - `DutchPayRepository.create` 에 sourceExpenseRowId 파라미터 추가
  - 반복 거래 변환 (`showRecurringEditDialog(fromExpense:)`)은 이미 `tx_detail_dialog` 에 구현돼 있던 상태

- [x] **#133 ExportDialog — CSV 내보내기** (commit `4be832e`)
  - `pubspec.yaml` 에 `share_plus: ^10.1.4` 추가 (`flutter pub get` 필요)
  - `features/expense/presentation/export_dialog.dart` 신규
    - 기간(주간/이번 달/분기/올해/직접 선택) + 포함(거래/카테고리/자산) 선택
    - GET `/expenses` + categories + 자산 → CSV 빌드 → Share.shareXFiles
  - More 화면에 "내보내기" 진입점 추가
  - **잔여**: xlsx/PDF 포맷은 별도 패키지(`excel`, `pdf`) 필요 — 추후 작업

- [x] **#134 Asset 다이얼로그 분리 — Add/CardAdd/InvestmentAdd/Detail** (commit `ca09156`)
  - `asset_edit_dialog.dart` 진입점 4종 신설:
    - `showAssetAddDialog(context, presetType?)` — 일반
    - `showCardAddDialog(context)` — CREDIT_CARD/CHECK_CARD chip 만 노출
    - `showInvestmentAddDialog(context)` — INVESTMENT chip 만
    - `showAssetDetailDialog(context, asset)` — 수정/삭제
  - `AssetMobile` `_TypeGroup` 에 `_GroupKind` enum 추가, 그룹별 "추가" 버튼이 적절한 다이얼로그 호출
  - `showAssetEditDialog` 는 backcompat wrapper 로 유지
  - **잔여**: front `CardAddDialog`/`InvestmentAddDialog` 의 카드 카탈로그·증권사 카탈로그 매핑은 v0.2+ 에서 별도 (현재는 일반 폼 + 자산 종류 chip 제한만)

---

## 우선순위 5 — v0.2+ 통합/확장

- [x] **#135 Recurring 자동 실행 + 전일 알림** (서버측 구현 확인)
  - `autoLog=Y` → 백엔드 `RecurringTransactionScheduler` (`@Scheduled(cron = "0 0 0 * * *")`) 가 daily 실행 — **클라이언트 작업 불필요**
  - **잔여 — defer**: `notifyDayBefore=Y` D-1 푸시는 `flutter_local_notifications` + 플랫폼 설정(AndroidManifest, iOS plist) 필요. 컨테이너에서 검증 불가하므로 별도 작업으로 분리.

- [x] **#136 Settings 추가 섹션 — 카테고리/예산/반복/알림/계정/데이터** (#124 와 통합 처리, commit `6b89258`)

- [ ] **#137 FilterDialog 백엔드 query param 이동 (v0.2)** — defer
  - 백엔드 `/expenses` GET 은 `categoryId`, `assetId` (단일) 만 지원
  - multi-select 필터링은 백엔드 endpoint 확장(List 파라미터) 필요 — 백엔드 작업 후 클라이언트 연결

- [x] **#139 Group 상세 화면** (commit `?`)
  - `domain/group_member.dart` 신규 (plain class, freezed 회피)
  - `GroupRepository` 에 getDetail / removeMember / changeMemberRole 추가
  - `groupDetailProvider` family<int> 신설
  - `presentation/group_detail_screen.dart` 신규
    - 그룹 헤더, 초대 코드(복사 + 재발급), 멤버 리스트(역할 배지/메뉴)
  - `/groups/:id` 라우트 등록, `group_screen` 탭 시 navigate
  - **잔여**: 거래 공유, 정산 내역 등 그룹 거래 관련 기능은 별도 (#137 백엔드 multi-select 와 연계)

---

## 완료된 작업 (참고)

### 이전 세션
- [x] #111 Home 화면 — front 디자인 미러 (commit `6dce458`)
- [x] #112 Asset 화면 — front 디자인 미러 (commit `6dce458`)
- [x] #130 Dashboard 하드코드 색 10곳 다크 토큰화 (commit `2acb824`)
- [x] #138 color_parse 에 oklch() CSS 함수 지원 (commit `2acb824`)

### 이번 세션 (요약)
- [x] #125 TRANSFER 이체 옵션 (`55d2146`)
- [x] #131 HideAmountsUnlockDialog (`ba20640`)
- [x] #133 ExportDialog CSV (`4be832e`)
- [x] #134 Asset 다이얼로그 4종 분리 (`ca09156`)
- [x] #132 Tx → DutchPay/Recurring 변환 (`47c3342`)
- [x] #124 + #136 Settings 7섹션 (`6b89258`)
- [x] #139 Group 상세 화면

### 후속 적용 필요
- `flutter pub get` — `share_plus` 패키지 다운로드 필요 (#133)
- 컨테이너 GitHub App 권한 풀린 뒤 `git push -u origin claude/review-pending-work-4btvY`
- iOS 빌드 시 `share_plus` 의 Info.plist `LSApplicationQueriesSchemes` 자동 처리됨 (변경 없음 예상)

---

# 신규 발견 항목 — front 전수 비교 결과 (2026-05-06)

> 3개 분석 agent (core / auxiliary / cross-cutting) 가 front `porest-desk-front` 와 Flutter app 을 전수 비교해 도출. 누락 기능 / 미러 안 된 다이얼로그 / 미사용 endpoint 위주, 픽셀 폴리시는 제외.
> ID 체계: #200~ 신규 부여. 작업량 S(<1h) / M(1~3h) / L(>3h).

## A. 다국어 / i18n (인프라 0%)

> Flutter `lib/l10n/` 빈 폴더, `pubspec` 에 `flutter_localizations` 미선언, `app.dart` 에 delegate 미등록, 101 lib 파일에 한글 하드코딩. front 는 ko/en 두 언어 + 14개 도메인 JSON.

- [x] **#200 i18n 인프라 부트스트랩** (commit `3819055`)
- [x] **#201 i18n: common.arb** (commit `5171f9d` 부분) — action* 14키 + state* 3키 ARB. 도메인 화면 호출부 마이그레이션은 후속
- [x] **#202 i18n: layout.arb** (commit `5171f9d`) — nav* 24키 ARB + MobileTabBar/MoreScreen 마이그레이션. mobile_header 는 후속
- [x] **#203 i18n: dashboard.arb 추가** (commit `d773130`) — 19키 (title/greeting/totalAssets/recent/upcoming/trend/empty 등)
- [x] **#204 i18n: expense.arb 추가** (commit `d773130`) — 32키 (title/filter/types/transfer/summary 등)
- [x] **#205 i18n: asset.arb 추가** (commit `c7d3f9c`) — 21키 ARB (assetTitle/totalBalance/empty/types/groups). 화면 측 호출부 마이그레이션은 후속
- [x] **#206 i18n: calendar.arb 추가** (commit `d773130`) — 25키 (title/views/event/labelMgmt/holidayMgmt/repeat 등)
- [x] **#207 i18n: todo.arb 추가** (commit `3de50bf`) — 19키 (status/priority/subtask/view 등). 화면 호출부 마이그레이션은 후속
- [x] **#208 i18n: memo.arb 추가** (commit `3de50bf`) — 9키. 화면 호출부 마이그레이션은 후속
- [ ] **#209 i18n: dutchPay.arb + group.arb** (S) — front `dutchPay.json` (30) + `group.json` (57)
- [x] **#210 i18n: notification.arb** (commit `4ae6f81`) — 11키 ARB + NotificationScreen 마이그레이션
- [ ] **#211 i18n: login.arb + user.arb** (S) — front `login.json` (5) + `user.json` (15)

## B. 인증 / 사용자

- [x] **#220 비밀번호 변경 화면 + repository** (commit `2ab6458`) — Settings 계정 섹션에 진입점, 8자 이상 검증
- [x] **#221 UserPreferences (budgetAlertThreshold) Provider/UI** (commit `2ab6458`) — repository 메서드만 추가, UI 노출은 추후 (#256 와 연계)

## C. 대시보드

- [x] **#230 DashboardSummary endpoint + provider** (commit `7cae516`) — `domain/dashboard_summary.dart` + `dashboard_repository.dart` + `dashboardSummaryProvider` + `_UpcomingCard` 위젯
- [x] **#231 Dashboard layout GET/PATCH** (commit `7cae516`) — repo `getLayout/updateLayout` + provider. UI 측 위젯 재배치 화면은 후속
  - 앱 쪽 읽기(`dashboardLayoutProvider` + `getLayout`)는 되걷었다 — 재배치 화면이 끝내 안 와서 읽는 화면이 0개인 채
    포그라운드 복귀마다 무효화만 돌고 있었다("갱신하고 있다" 는 착시). 서버 엔드포인트는 그대로다.
    재배치 화면을 만들 때 provider 를 다시 세우면 된다.
  - 쓰기(`updateLayout`)도 마저 걷었다 — 읽기를 걷고 나니 **읽는 짝 없는 쓰기 메서드 하나만** 남아 있었고,
    그마저 부르는 곳이 처음부터 0개였다. `DashboardRepository` 는 `summary()` 로 계속 쓰이므로 클래스·provider 는 남는다.
    서버 `PATCH /dashboard/layout` 은 그대로다.
- [ ] **#232 HomeDesktop 5종 카드** (L) — 월별 막대 / 카테고리 도넛 / 예산 / 예정 결제 / 일정. 데스크톱 레이아웃 부재 (모바일 단일)
- [x] **#233 월별 수입/지출 BarChart 표시** (commit `e7db6fa`) — Dashboard 에 `_MonthlyTrendCard` 추가

## D. 자산 / 이체

- [x] **#240 AssetDetailDialog (잔액 추이 + 최근 거래)** (commit `2463f62`) — `asset_detail_dialog.dart` 신규, 헤더+12주 차트+최근5건+편집/삭제
- [x] **#241 자산 잔액 추이 API** (commit `90f51a6`) — `balanceTrend(id, weeks)` + `assetBalanceTrendProvider`
- [x] **#242 자산 단건 GET** (commit `90f51a6`) — `getById` + `assetByIdProvider`
- [x] **#243 자산 순서 변경 PATCH** (commit `90f51a6`) — `reorder(items)` 추가, UI 드래그는 추후
- [x] **#244 자산 이체 내역 리스트** (commit `90f51a6`) — `listTransfers(startDate, endDate)` + `assetTransfersProvider`. UI 화면은 추후
- [x] **#245 CardAddDialog 카드 카탈로그 연결** (commit `ff38c92`) — `card_catalog_picker.dart` 재사용 picker, AssetEditBody 카드 모드에서 검색 → 자동 입력. 투자 카탈로그(증권사 검색)는 후속

## E. 거래 / 카테고리 / 예산

- [x] **#250 카테고리 reorder PATCH** (commit `62c381d`) — repository 메서드 추가, UI 드래그는 추후
- [x] **#251 일/주/연 요약 endpoint** (commit `4dd9266`) — `domain/stats_summaries.dart` + `daily/weekly/yearly` repo + 3 provider
- [x] **#252 캘린더 이벤트별/할일별 거래 목록** (commit `4dd9266`) — `expensesByCalendarEventProvider` / `expensesByTodoProvider`
- [ ] **#253 FilterDialog 다차원 필터 확장** (M) — front: period(month/week/3m/custom) + types + categoryIds + assetIds + min/max 금액. Flutter 는 cat/asset 두 차원만 (#137 별도)
- [x] **#254 자산별 거래 필터 endpoint provider** (commit `4dd9266`) — `expensesByAssetIdProvider`. ExpenseScreen 측 URL 진입점 배지는 후속
- [x] **#255 거래 검색 고급 필터 UI** (commit `ff8de9b`) — SearchScreen 에 minAmount/maxAmount/startDate/endDate + BottomSheet
- [x] **#256 예산 준수율 6개월 차트** (commit `1bf73ee`) — `compliance(months)` + `budgetComplianceProvider` + `_ComplianceCard` 막대 차트
- [ ] **#257 BudgetEditDialog "전체 월 예산" 모드** (S) — front `MonthlyBudgetDialog`. Flutter 카테고리 단건만
- [x] **#258 BudgetManager 일괄 액션** (commit `294375c`) — AppBar PopupMenu: 전월 복사 / 전체 삭제 (확인 다이얼로그)

## F. 프리셋

- [ ] **#260 PresetManager 드래그 reorder** (S) — front 408줄. Flutter sortOrder 필드는 백엔드 있으나 UI 미사용

## G. 반복 거래

- [x] **#270 RecurringFromTxDialog 풀 폼 (next-3 preview)** (commit `c018ba8`) — `_previewNextDates` 헬퍼 + 다음 예정일 칩 strip 추가. 종료 mode COUNT 는 백엔드 미지원이므로 단일 endDate 유지
- [ ] **#271 RecurringManager 일괄 액션** (S) — front 547줄, 일부는 이미 미러됨. 나머지 minor

## H. 통계

- [x] **#280 자산별 지출 분포 차트** (commit `e7db6fa`) — Stats `_AssetUsageList` 섹션 추가 (합계/비율/막대)
- [x] **#281 카테고리 트렌드 라인 차트** (commit `c42e099`) — yearlySummary.monthlyAmounts 활용, 카테고리 chip strip + 12개월 LineChart
- [x] **#282 예산 vs 실제 차트** (commit `66a08a6`) — `_BudgetVsActual` 카테고리별 spent/budget bar (over=danger)
- [x] **#283 가맹점 분포·추이 차트** (commit `aefb778`) — `_MerchantTop` 확장: 펼치기, 1회 평균, % 점유율 표시
- [x] **#284 전년 대비 차트 + yearlySummary 연동** (commit `5b822f6`) — Stats `_YearOverYearChart`. 12개월 BarChart, 전년 vs 올해 totalExpense 비교 + delta% 배지
- [x] **#285 카테고리 부모-자식 드릴다운** (commit `152cbfa`) — `_CategoryDonut` 을 ConsumerStatefulWidget 으로 변환, `_activeParentId` 상태로 드릴다운, fallback 평면 응답 처리

## I. 더치페이 / 정산

- [ ] **#290 더치페이 단건 GET + 수정** (M) — front `useDutchPay(id)` / `useUpdateDutchPay`. Flutter repo `get`/`update` 없음, 수정 UI 없음
- [x] **#291 DutchPayFromTxDialog 그룹 멤버 picker + 1인당 자동계산** (commit `980330c`) — siblingMembersProvider 기반 다중선택 BottomSheet, EQUAL 시 1인당 표시

## J. 캘린더

- [x] **#300 캘린더 라벨(EventLabel) CRUD 다이얼로그** (commit `3c2c16a`) — `event_label_management_dialog.dart` + 신규/편집/삭제, 8색 팔레트, AppBar 우측 액션
- [x] **#301 공휴일(Holiday) 도메인 + 관리 다이얼로그** (commit `302c6e5`) — domain/repo/provider + 연도 기반 조회 + 사용자 정의(CUSTOM) 추가/삭제, 매년 반복 토글. CalendarScreen 메뉴 진입점
- [x] **#302 사용자 캘린더(UserCalendar) 다중 관리** (commit `d5b6ea4`) — domain/repo/provider + 관리 다이얼로그 (이름/색/visibility 토글/삭제). CalendarScreen 메뉴 진입점
- [x] **#303 캘린더 통합 집계 API** (commit `1b3900d`) — `aggregate(startDate, endDate)` + `calendarAggregateProvider`. UI 측 활용은 후속
- [ ] **#304 캘린더 다중 뷰 (week/day/year/agenda)** (L) — front 5종 view + dnd-provider. Flutter month 단일 뷰
- [ ] **#305 캘린더 소스 토글 (events/expenses/holidays/group)** (S) — front `calendar-source-toggle.tsx`. Flutter 미구현

## K. 이벤트 코멘트

- [x] **#310 EventComment 도메인 + repository** (commit `2cfc0de`) — list/create/update/delete + `eventCommentsProvider` family<int>. UI 패널은 후속

## L. Todo

- [x] **#320 TodoProject CRUD + 관리 다이얼로그** (commit `4f03082`) — domain/repo/provider + `todo_project_management_dialog.dart` (이름/설명/색 + 인라인 편집). 칸반/그룹 뷰는 #322 별도
- [x] **#321 TodoTag CRUD + 관리 다이얼로그** (commit `4f03082`) — domain/repo/provider + `todo_tag_management_dialog.dart`. `updateTags(id, tagIds)` API 는 #62c381d 에서 추가 완료
- [x] **#322 Todo 칸반 보드 뷰** (commit `bac848e`) — `todo_kanban_view.dart` 3컬럼 (대기/진행중/완료), DragTarget+LongPressDraggable, AppBar 토글
- [x] **#323 Todo 서브태스크 UI** (commit `53f9909`) — todo_edit_dialog 에 _SubtaskSection (편집 모드 전용), 추가/체크 토글/삭제
- [x] **#324 Todo reorder API** (commit `62c381d`) — `reorder(items)` + `getById` + `getSubtasks` + `updateTags`
- [x] **#325 Todo 통계 (TodoStats)** (commit `62c381d`) — `domain/todo_stats.dart` + `stats()` + `todoStatsProvider`
- [x] **#326 Todo 노트 마크다운 미리보기** (commit `fccf8dd`) — `markdown_preview.dart` (h1~h3/quote/체크리스트/불릿/inline bold/italic/code) + todo_edit_dialog 미리보기 토글
- [x] **#327 Todo 빠른 추가 + 다중 필터** (commit `a991872`) — AppBar bottom 빠른 추가 입력 + 상태/우선순위 칩 (가로 스크롤)
- [ ] **#328 Todo 핀 토글 응답 매핑/optimistic** (S) — front `togglePin` 응답 매핑. Flutter pin 호출만, 응답 미사용

## M. 메모

- [x] **#340 MemoFolder 도메인 + 트리 관리 다이얼로그** (commit `b5bbb92`) — domain/repo/provider + tree builder + 폴더 관리 다이얼로그 (이름/부모/CRUD)
- [x] **#341 메모 검색 (search 파라미터)** (commit `2445776`) — `list({folderId, search})` + `memoSearchProvider` + AppBar bottom 검색 입력
- [ ] **#342 3패널 메모 에디터 (트리/리스트/프리뷰)** (L) — front `MemoEditorWidget` + `MemoFolderTree` + `MemoList` + `MemoPreview`. Flutter 단일 ListView

## N. 저금 목표

- [x] **#350 SavingGoal reorder PATCH** (commit `62c381d`) — `reorder(items)` 추가
- [x] **#351 SavingGoal 단건 GET** (commit `62c381d`) — `getById` + `savingGoalByIdProvider`

## O. 그룹

- [x] **#360 GroupType CRUD + 관리 다이얼로그** (commit `bc832d9`) — domain/repo/provider + `group_type_management_dialog.dart` (이름/색 + 인라인 편집)
- [x] **#361 그룹 형제 멤버 조회 (getSiblingMembers)** (commit `9807705`) — `SiblingMember` plain class + `getSiblingMembers` + `siblingMembersProvider`
- [x] **#362 그룹 일정 탭 + 지출 탭** (commit `ed76a6c`) — `groupEvents` + `expensesByGroup` repos/providers + GroupDetailScreen 3-Tab 구조 (멤버·초대 / 일정 / 지출)
- [x] **#363 그룹 수정/삭제 UI 진입점** (commit `b98e2c7`) — GroupDetailScreen AppBar PopupMenu (OWNER 만), 수정/삭제 다이얼로그

## P. 카드

- [x] **#370 카드 사용 가능 혜택(availableBenefits) API** (commit `93a04ff`) — `availableBenefits(cardRowId, expenseCategoryRowId?)` 추가. UI 자동 추천은 후속
- [x] **#371 CardPerformance 도메인 + 진척 바** (commit `de447c1`) — `domain/card_performance.dart` + repo + provider + `card_performance_bar.dart` 위젯 + AssetDetailDialog 카드 자산일 때 노출
- [x] **#372 CardBenefitMapping 도메인 + 매핑 다이얼로그** (commit `3dee797`) — domain/repo/provider + 매핑 관리 dialog (혜택→카테고리 매핑, 시스템/커스텀 구분), CardScreen AppBar 진입점
- [x] **#373 CardCatalogCombobox** (commit `ff38c92`) — `showCardCatalogPicker` BottomSheet (검색+신용/체크 칩+페이지) → CardCatalogSummary 반환
- [x] **#374 카드 검색 benefitType / includeDiscontinued 필터** (commit `93a04ff`) — 칩 + 단종 토글 추가
- [x] **#375 카드 카탈로그 페이지네이션** (commit `93a04ff`) — `CardCatalogPage` + paginator (이전/다음, 총 N건)

## Q. 알림

- [x] **#380 알림 스트림 서비스** (commit `6c351da`) — polling 기반 NotificationStreamService + Stream<AppNotification>. authProvider 와 연동 (login=start / logout=stop). FCM 도입은 후속 (svc.start 가 firebase_messaging.onMessage 로 교체)
- [x] **#381 헤더 NotificationBell + unread badge** (commit `9807705`) — `_NotificationBell` 위젯, unreadCount 99+ 표시, /notifications 라우트

## R. 파일 첨부

- [x] **#390 File 업로드/조회/삭제 인프라** (commit `350f100`) — image_picker + file_picker 패키지, FileAttachment domain, FileRepository (upload multipart / list / delete / downloadUrl), FileAttachmentSection 위젯. TxDetailDialog 에 EXPENSE 단위 첨부 섹션 embed. iOS Info.plist 권한 메시지는 후속

## S. 타이머 (defer 결정 필요)

- [ ] **#395 Timer (POMODORO/COUNTDOWN/STOPWATCH)** (L 또는 N/A) — front `timerEngine.ts` + `timer.json` 14 키. 가계부 모바일 비핵심 → defer 권장. dashboard 마이그레이션 시 timer 카드 섹션 처리 결정 필요

## T. 공유 UI / 디자인 시스템

- [x] **#400 PButton/PField 토큰 위젯** (commit `d098f74`) — `shared/widgets/p_button.dart` (variant×size + loading + fullWidth) + PField (label+input+error/hint)
- [x] **#401 PModal/PConfirm helper** (commit `d098f74`) — `shared/widgets/p_modal.dart` (showPModalSheet + showPConfirmDialog 통일 wrapper)
- [x] **#402 PToast (sonner 등가)** (commit `d098f74`) — `shared/widgets/p_toast.dart` (success/error/warning/info/plain 톤, action 지원)
- [x] **#403 PDateInput / PTimeInput** (commit `d098f74`) — input 인라인 picker, allowClear 지원
- [x] **#404 PColorPicker / PIconPicker** (commit `d098f74`) — `shared/widgets/p_color_picker.dart` (8색 팔레트 + 24개 lucide 아이콘)
- [x] **#405 PSpeedDial (FAB-with-children)** (commit `d098f74`) — `shared/widgets/p_speed_dial.dart` 펼침 애니메이션
- [x] **#406 RichTextEditor — 마크다운 미리보기로 축소 (defer 결정)** (commit `fccf8dd` `#326` 와 통합) — flutter_quill 미사용, MarkdownPreview 채택
- [ ] **#407 PCommandPalette (Cmd/Ctrl+K)** (M, defer) — 모바일 비핵심

## U. 마스킹 / hideAmounts

- [x] **#420 MaskAmount 등가 위젯** (commit `a106ad9`) — `shared/widgets/masked_amount.dart` (MaskedAmount/MaskedBlock/formatMaybeMasked)
- [x] **#421 차트 tooltip 마스킹** (commit `a106ad9`) — NetWorthChart tooltip + leftTitles 마스킹. 다른 차트(BarChart/PieChart) 일관 적용은 점진
- [x] **#422 hideAmounts unlock 일관성** (#131 #420 commit `ba20640`,`a106ad9`) — mobile_header/asset_screen 외에도 MaskedAmount/MaskedBlock 위젯이 자체적으로 settings.hideAmounts 를 watch 하므로 어디서든 일관 적용 가능

## V. 라우팅 / 테마

- [x] **#430 카드 상세 paramized 라우트** (commit `ff38c92`) — `/cards/:id` 라우트 추가, card_screen 의 직접 push → context.push('/cards/N')
- [ ] **#431 card-settings 라우트** (M) — #372 와 묶임
- [ ] **#432 PDensity.cozy 키 정렬** (S) — front `cozy` ↔ Flutter `comfortable` 직렬화 키 mismatch. front prefs 동기화 시 깨짐

## W. 카테고리 색 팔레트

- [ ] **#440 카테고리 아이콘 팔레트(CAT_ICO_PALETTE) 이식** (S) — front `primitives.tsx`. Flutter `colors.dart` 는 mist/mossy/bark/sunlit/berry/sky 만, 카테고리별 색 매핑 미이식

---

## 카운트 요약

| 영역 | 신규 항목 | 작업량 분포 |
|---|---|---|
| A. i18n | 12 | M 5, S 7 |
| B. 인증/사용자 | 2 | S 2 |
| C. 대시보드 | 4 | L 1, M 2, S 1 |
| D. 자산 | 6 | L 2, M 2, S 2 |
| E. 거래/카테고리/예산 | 9 | M 4, S 5 |
| F. 프리셋 | 1 | S 1 |
| G. 반복 | 2 | M 1, S 1 |
| H. 통계 | 6 | M 5, S 1 |
| I. 더치페이 | 2 | M 2 |
| J. 캘린더 | 6 | L 3, M 1, S 2 |
| K. 이벤트 코멘트 | 1 | M 1 |
| L. Todo | 9 | L 2, M 3, S 4 |
| M. 메모 | 3 | L 2, S 1 |
| N. 저금 목표 | 2 | S 2 |
| O. 그룹 | 4 | L 1, M 2, S 1 |
| P. 카드 | 6 | L 1, M 3, S 2 |
| Q. 알림 | 2 | L 1, S 1 |
| R. 파일 | 1 | L 1 |
| S. 타이머 | 1 | defer |
| T. 공유 UI | 8 | L 1, M 2, S 5 |
| U. 마스킹 | 3 | S 3 |
| V. 라우팅/테마 | 3 | M 1, S 2 |
| W. 팔레트 | 1 | S 1 |
| **합계** | **94** | **L 15, M 34, S 44, defer 1** |

대략 코어 30 + 보조 31 + 횡단 33. 

## 권장 진행 순서 (의견)

1. **#200 i18n 인프라** — 모든 후속 화면 작업의 기반. 한 번에 인프라만 깔고 후속 #201-#211 도메인별 ARB 는 다른 기능 작업과 병행
2. **#240 AssetDetailDialog**, **#270 RecurringFromTxDialog 풀 폼**, **#291 DutchPayFromTxDialog 풀 폼** — 이미 진입점은 있지만 UX 깊이가 얕은 항목
3. **#230-#233 대시보드** — 홈 화면이 약함. summary endpoint + 5종 카드
4. **#380-#381 알림 채널** — UX 핵심 (FCM 도입은 권한 풀린 뒤)
5. **#390 파일 첨부**, **#372 CardBenefitMapping** — 큰 도메인이라 별도 스프린트
6. **#400-#407 디자인 시스템** — 디자인 일관성. i18n 직후 또는 병행
7. 나머지는 우선순위 낮게 분산
