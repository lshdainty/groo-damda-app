// 구독 시트의 기능 비교표는 **Pro 가 실제로 주는 것**만 적는다.
//
// 한동안 표가 없는 제한을 광고했다 — 월 100건 · CSV 가져오기/내보내기 ·
// 다중 캘린더 공유 · 카드 혜택 추천. 코드에는 그런 제한이 하나도 없고
// (플랜 features 는 `["SECURITIES"]` 뿐, 서버 게이트도 증권 API 뿐) Free 계정으로
// 전부 됐다. 줄이 되살아나면 여기서 깨진다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import '../../support/plain_text.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/features/subscription/presentation/subscription_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_en.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';

/// 표에서 걷어 낸 네 줄의 한국어 문구. 키를 지웠으므로 문자열로 붙잡는다 —
/// 다시 넣으려면 arb 에 같은 문구를 되살려야 하고, 그 순간 이 테스트가 깨진다.
const _removedRows = <String>[
  '월 거래 기록',
  '100건',
  '무제한',
  'CSV · Excel 가져오기 / 내보내기',
  '다중 캘린더 공유',
  '카드 혜택 추천',
];

/// 가운뎃점은 **U+00B7**, 양옆에 공백 하나씩. 이스케이프로 박아 둔다 —
/// 눈으로는 같아 보이는 U+2022(•) · U+30FB(・) 를 붙여 넣어도 여기서 걸린다.
const _sep = ' \u00B7 ';

/// 증권 줄은 **세 레포가 같은 문자열**을 쓴다. 웹이
/// `tests/subscription-copy-matches-gates.test.ts` 에서 전문 `toBe` 로 잠갔고,
/// 설명서(`docs/asset/overview.md`)도 같은 말로 고쳤다.
///
/// 여기서 `l.subFeatSecurities` 로만 확인하면 **아무것도 안 지킨다** — arb 가 무슨 말로
/// 바뀌든 테스트가 따라간다. 웹은 웹대로 잠겨 있으므로 앱이 옛 말로 돌아가도
/// **웹 CI 는 안 깨지고** 세 레포가 조용히 어긋난다. 그래서 전문으로 붙잡는다.
const _securitiesKo = '증권사 연동${_sep}실시간 시세${_sep}자산 실시간 금액';
const _securitiesEn =
    'Securities link${_sep}real-time quotes${_sep}real-time asset value';

/// 설명서는 '자산 평가(액)' 을 **매일 오후 4시 종가 스냅샷**이라는 뜻으로 쓴다.
/// Pro 게이트가 주는 건 그게 아니라 **자산 상세·편집의 실시간 금액 조회**
/// (`useInvestValuation` → `features.includes("SECURITIES")`)다 — 겹치는 단어가
/// '평가' 라 혜택 한 줄이 설명서와 다른 것을 가리켰다.
const _ambiguousWord = '평가';

Widget _app() => ProviderScope(
  // Free 계정 고정 — 기능 줄 내용은 플랜과 무관하지만 네트워크를 타지 않게 막는다.
  overrides: [
    mySubscriptionProvider.overrideWith((ref) async => null),
    subscriptionPlansProvider.overrideWith(
      (ref) async => const <SubscriptionPlanInfo>[],
    ),
    myFeaturesProvider.overrideWith((ref) async => MyFeatures.empty),
  ],
  child: MaterialApp(
    theme: GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: const SubscriptionScreen(),
  ),
);

/// 기능 비교 = '기능 비교' 제목 아래 List — 줄 셋의 이름이 든 목록. 요금 줄의 'Free' / 'Pro' 와 섞이지 않게
/// 이 목록 안쪽만 센다.
Finder _table(AppLocalizations l) =>
    find.byKey(const ValueKey('subscription-features'));

Future<void> _openSheet(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
}

void main() {
  final l = AppLocalizationsKo();

  testWidgets('비교표에 없는 제한을 광고하지 않는다 — 증권 한 줄만 Pro 전용', (tester) async {
    await _openSheet(tester);

    expect(_table(l), findsOneWidget);

    for (final gone in _removedRows) {
      expect(
        findPlain(gone),
        findsNothing,
        reason: '"$gone" 은 코드에 없는 제한이다 — 표에 적으면 광고가 된다',
      );
    }

    // 남는 줄은 셋. 증권만 Pro 전용(별표).
    expect(
      find.descendant(of: _table(l), matching: findPlain(l.subFeatLedger)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _table(l), matching: findPlain(l.subFeatBudget)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _table(l), matching: findPlain(l.subFeatSecurities)),
      findsOneWidget,
    );
  });

  testWidgets('Free/Pro 표시가 깨지지 않는다 — "Free · Pro" 둘 · "Pro" 하나', (
    tester,
  ) async {
    await _openSheet(tester);

    final table = _table(l);

    // 가계부 · 예산은 둘 다, 증권은 Pro 에만 — 폰은 표 대신 줄이고 값 글이 그 기능이 있는 플랜이다.
    expect(
      find.descendant(of: table, matching: findPlain('Free · Pro')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: table, matching: findPlain('Pro')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: table, matching: findPlain('Free')),
      findsNothing,
    );
  });

  testWidgets('증권 줄은 웹과 같은 문구로 뜬다 — 표에 \'$_ambiguousWord\' 가 없다', (
    tester,
  ) async {
    await _openSheet(tester);

    expect(
      find.descendant(of: _table(l), matching: findPlain(_securitiesKo)),
      findsOneWidget,
      reason: '웹이 toBe 로 잠근 그 문자열 그대로여야 한다',
    );

    // 표의 **어느 줄도** 그 말로 광고하지 않는다. 증권 줄만 보지 않는 건
    // 가계부·예산 줄이 나중에 같은 단어를 물고 들어오는 것도 막기 위해서다.
    expect(
      find.descendant(
        of: _table(l),
        matching: findPlainContaining(_ambiguousWord),
      ),
      findsNothing,
      reason: '설명서가 \'$_ambiguousWord\' 를 하루 한 번 종가 스냅샷이라는 다른 뜻으로 쓴다',
    );
  });

  test('arb 문구가 웹의 toBe 와 한 글자도 다르지 않다 — ko · en', () {
    expect(AppLocalizationsKo().subFeatSecurities, _securitiesKo);
    expect(AppLocalizationsEn().subFeatSecurities, _securitiesEn);

    expect(
      AppLocalizationsKo().subFeatSecurities,
      isNot(contains(_ambiguousWord)),
    );
    expect(
      AppLocalizationsEn().subFeatSecurities,
      isNot(contains('valuation')),
    );

    // 구분자가 U+00B7 그대로인지 — 웹이 같은 글자로 잠갔다.
    expect(AppLocalizationsKo().subFeatSecurities.split(_sep), hasLength(3));
    expect(AppLocalizationsEn().subFeatSecurities.split(_sep), hasLength(3));
  });

  // 잠긴 건 증권 줄뿐이다. Free 잠금 안내는 원래 '$_ambiguousWord' 를 쓰지 않으므로
  // 이번 교체 범위 밖이고, 그대로 둔다는 것을 여기서 못박는다.
  test('subFreeLockedDesc 는 건드리지 않았다', () {
    expect(AppLocalizationsKo().subFreeLockedDesc, '증권 연동 · 실시간 시세가 잠겨 있어요');
  });
}
