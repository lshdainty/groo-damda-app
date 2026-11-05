// I-05 05-3 자산 화면 — 실제 `AssetScreen` 을 띄워 지시서 값을 잰다(폰 360, 가장 나쁜 값).
//
// 55 순자산 요약(눈 · 금액 · 지표) · 56 자산 줄(한도 막대 · 외화 · 가림 · 총액 제외) · 57 추이 차트(선 + 점) ·
// 60 저축 목표(원까지) · 61 빈 화면 · 62 카드마다 따로 불러오고 실패 · 74 띠 틈(맨 위 0 · 사이 8 · 맨 아래 0) ·
// 화면 끝까지 닿기(360).
import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/hide_cards_repository.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_summary.dart';
import 'package:groo_damda_app/features/asset/domain/net_worth_point.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_screen.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';

import '../../support/hide_cards_fake.dart';
import '../../support/plain_text.dart';

const _longName = '주거래 입출금 통장 — 아주 길게 지은 별칭 서른 글자까지 늘려 본다 하나 둘';

Asset _a(
  int id,
  String name,
  String type, {
  int balance = 0,
  String? institution,
  int? creditLimit,
  String? currency,
  double? rate,
  String included = 'Y',
  String hidden = 'N',
  String? memo,
  int? paymentDay,
  List<AssetHolding> holdings = const [],
}) => Asset(
  rowId: id,
  assetName: name,
  assetType: type,
  balance: balance,
  institution: institution,
  creditLimit: creditLimit,
  currency: currency,
  exchangeRate: rate,
  isIncludedInTotal: included,
  isAmountHidden: hidden,
  memo: memo,
  paymentDay: paymentDay,
  holdings: holdings,
);

final _assets = [
  _a(
    1,
    _longName,
    'BANK_ACCOUNT',
    balance: 1234567890,
    institution: '가나다라마바사은행',
  ),
  _a(
    2,
    '해외 달러 통장',
    'BANK_ACCOUNT',
    balance: 1000,
    currency: 'USD',
    rate: 1385,
    included: 'N',
  ),
  _a(3, '가린 통장', 'BANK_ACCOUNT', balance: 5000, hidden: 'Y'),
  _a(
    4,
    '카드 일흔다섯',
    'CREDIT_CARD',
    balance: -7500000,
    creditLimit: 10000000,
    paymentDay: 15,
    institution: '하늘카드',
  ),
  _a(5, '카드 아흔다섯', 'CREDIT_CARD', balance: -9500000, creditLimit: 10000000),
  _a(6, '카드 한도 넘침', 'CREDIT_CARD', balance: -12345678, creditLimit: 10000000),
  _a(
    7,
    '주식 계좌',
    'INVESTMENT',
    balance: 3000000,
    holdings: const [AssetHolding(holdingName: '종목 하나', quantity: '1')],
  ),
  _a(8, '주택 담보 대출', 'LOAN', balance: -50000000),
];

final _goals = [
  const SavingGoal(
    rowId: 1,
    title: '저축 목표 하나 — 이름이 아주 길게 이어져 줄이 접히는 경우',
    targetAmount: 9999999999,
    currentAmount: 1234567890,
    deadlineDate: '2028-12-31',
  ),
  const SavingGoal(
    rowId: 2,
    title: '달성한 목표',
    targetAmount: 4900,
    currentAmount: 100,
    isAchieved: 'Y',
  ),
];

List<NetWorthPoint> _trend({int base = -12345678901}) => [
  for (var i = 0; i < 12; i++)
    NetWorthPoint(year: 2026, month: i + 1, netWorth: base + i * 1000000000),
];

Future<void> _pump(
  WidgetTester tester, {
  double width = 360,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Future<List<Asset>> Function()? assets,
  Future<AssetSummary> Function()? summary,
  Future<List<NetWorthPoint>> Function()? trend,
  Future<List<SavingGoal>> Function()? goals,
  Map<int, InvestmentValuation> valuation = const {},
  Set<String> hidden = const {},
}) async {
  tester.view.physicalSize = Size(width * 2, 6000 * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        hideCardsRepositoryProvider.overrideWith(
          (ref) async => OkHideCardsRepository(),
        ),
        assetsProvider.overrideWith((ref) => (assets ?? () async => _assets)()),
        assetSummaryProvider.overrideWith(
          (ref, key) =>
              (summary ??
              () async => const AssetSummary(
                netWorth: -12345678901,
                totalAssets: 1234567890,
                totalDebt: 62345678,
                lastMonthNetWorth: -12000000000,
                changeAmount: -345678901,
                changePercent: -2.9,
              ))(),
        ),
        netWorthTrendProvider.overrideWith(
          (ref, months) => (trend ?? () async => _trend())(),
        ),
        investmentValuationMapProvider.overrideWith((ref) async => valuation),
        savingGoalListProvider.overrideWith(
          (ref) => (goals ?? () async => _goals)(),
        ),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? GrooTheme.dark()
            : GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: AssetScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  if (hidden.isNotEmpty) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AssetScreen)),
    );
    await container.read(settingsProvider.notifier).hideCards(hidden);
    await tester.pump();
  }
}

Finder get _bands => find.byKey(const ValueKey('screen-section'));
List<Rect> _rects(WidgetTester t) => [
  for (var i = 0; i < _bands.evaluate().length; i++) t.getRect(_bands.at(i)),
];

Finder _progressWithin(Finder row) => find.descendant(
  of: row,
  matching: find.byKey(const ValueKey('progress-fill')),
);

void main() {
  group('74 · 띠 — 맨 위 0 · 사이 8 · 맨 아래 0', () {
    testWidgets('띠 여섯(요약 · 계좌 · 투자 · 카드 · 대출 · 저축 목표)', (tester) async {
      await _pump(tester);
      final r = _rects(tester);
      expect(r.length, 6);
      final top = tester.getRect(find.byType(AssetScreen)).top;
      expect(r.first.top - top, 0, reason: '머리 바로 아래 첫 띠 — 틈 없음');
      for (var i = 0; i < r.length - 1; i++) {
        expect(r[i + 1].top - r[i].bottom, 8, reason: '띠 사이 8');
      }
      for (final b in r) {
        expect(b.left, 0);
        expect(b.right, 360, reason: '띠는 화면 폭 — 360 끝까지');
      }
      final list = tester.widget<ListView>(find.byType(ListView).first);
      final bottom = (list.padding ?? EdgeInsets.zero)
          .resolve(TextDirection.ltr)
          .bottom;
      expect(bottom, lessThan(200), reason: '마지막 띠 아래는 탭 바 보상뿐');
      expect(
        tester.getRect(find.byType(ListView).first).bottom - r.last.bottom,
        greaterThanOrEqualTo(0),
      );
    });

    testWidgets('투자 · 대출이 없으면 그 띠가 없다 — 넷', (tester) async {
      await _pump(
        tester,
        assets: () async => [
          for (final a in _assets)
            if (a.assetType != 'INVESTMENT' && a.assetType != 'LOAN') a,
        ],
      );
      expect(_bands, findsNWidgets(4));
    });
  });

  group('55 · 순자산 요약', () {
    testWidgets('눈 단추 — 이름 "금액 가리기 설정" · toggled 없음 · 보이는 40', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      final eye = find.byKey(const ValueKey('asset-eye'));
      expect(eye, findsOneWidget);
      expect(tester.widget<PButton>(eye).semanticLabel, '금액 가리기 설정');
      expect(tester.widget<PButton>(eye).variant, PButtonVariant.ghost);
      final node = tester.getSemantics(find.bySemanticsLabel('금액 가리기 설정'));
      // 눈 아이콘이 바뀌어도 이름은 하나 · 토글 상태(aria-pressed)는 없다
      // ignore: deprecated_member_use
      expect(node.hasFlag(SemanticsFlag.hasToggledState), isFalse);
      expect(tester.getSize(eye).height, greaterThanOrEqualTo(40));
      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
      handle.dispose();
    });

    testWidgets('금액 t12 700 · 음수는 U+2212 · 원까지 · "—" 없음', (tester) async {
      await _pump(tester);
      final t = tester.widget<Text>(findPlain('−12,345,678,901원'));
      expect(t.style?.fontSize, 32);
      expect(t.style?.fontWeight, FontWeight.w700);
      expect(find.text('—'), findsNothing);
      expect(find.textContaining('-1'), findsNothing, reason: '하이픈 부호 없음');
      expect(
        find.textContaining('−1', findRichText: true),
        findsWidgets,
        reason: 'U+2212 부호가 있다',
      );
    });

    testWidgets('불러오는 중은 Skeleton — "—" 가 아니다', (tester) async {
      await _pump(tester, summary: () => Completer<AssetSummary>().future);
      expect(find.byType(PSkeleton), findsWidgets);
      expect(find.text('—'), findsNothing);
      expect(findPlain('−12,345,678,901원'), findsNothing);
    });

    testWidgets('지표 셋은 한 줄에 하나(키-값 줄 세로) · 값 U+2212', (tester) async {
      await _pump(tester);
      final first = _bands.first;
      final rows = find.descendant(of: first, matching: find.byType(PListItem));
      expect(rows, findsNWidgets(3));
      final ys = [for (var i = 0; i < 3; i++) tester.getRect(rows.at(i)).top];
      expect(ys[0] < ys[1] && ys[1] < ys[2], isTrue);
      for (var i = 0; i < 3; i++) {
        expect(tester.getRect(rows.at(i)).right, 360, reason: '줄은 화면 끝까지');
      }
      expect(
        findPlain('−62,345,678원'),
        findsNothing,
        reason: '카드값은 카드 합계(절댓값)',
      );
    });
  });

  group('56 · 자산 줄', () {
    testWidgets(
      '카드 한도 막대 — 75% · 95% 는 fg-brand 그대로, 넘침은 fg-critical + "N원 초과"',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester);
        final c = PColors.light;
        final fills = find.byKey(const ValueKey('progress-fill'));
        Color colorOf(Element e) =>
            ((e.widget as Container).decoration as BoxDecoration).color!;
        // 막대 순서: 카드 셋(저축 목표 둘은 그 뒤)
        final els = fills.evaluate().toList();
        expect(colorOf(els[0]), c.fgBrand, reason: '75% — 색을 바꾸지 않는다');
        expect(colorOf(els[1]), c.fgBrand, reason: '95% — 색을 바꾸지 않는다');
        expect(colorOf(els[2]), c.fgCritical, reason: '한도 넘침');
        expect(findPlain('2,345,678원 초과'), findsOneWidget);
        expect(
          tester.widget<Text>(findPlain('2,345,678원 초과')).style?.fontWeight,
          FontWeight.w700,
        );
        expect(
          find.bySemanticsLabel('카드 한도 넘침 한도 10,000,000원 중 12,345,678원'),
          findsOneWidget,
          reason: '막대 이름 "{카드} 한도 {한도} 중 {사용}"',
        );
        expect(findPlain('7,500,000원 / 10,000,000원'), findsOneWidget);
        expect(
          tester.getSize(findPlain('7,500,000원 / 10,000,000원')).height,
          lessThan(24),
          reason: '넘치지 않으면 "사용 / 한도" 는 한 줄 — 빈 오른쪽 칸이 폭을 먹지 않는다',
        );
        handle.dispose();
      },
    );

    testWidgets('외화는 환산액 주 표기 + 아래 원 통화 · 총액 제외 · 가림 배지', (tester) async {
      await _pump(tester);
      expect(findPlain('1,385,000원'), findsOneWidget);
      expect(find.textContaining('1,000'), findsWidgets);
      expect(findPlain('총액 제외'), findsOneWidget);
      expect(findPlain('금액 숨김'), findsOneWidget);
      expect(findPlain('5,000원'), findsNothing, reason: '이 자산만 가린다');
    });

    testWidgets('줄은 ds List 누르는 줄 — 앞 로고 40 · 제목 말줄임 없이 접힘 · 설명 Tag Group', (
      tester,
    ) async {
      await _pump(tester);
      final row = find.byKey(const ValueKey('asset-row-1'));
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.byType(PListButtonItem)),
        findsOneWidget,
      );
      expect(findPlain(_longName), findsOneWidget, reason: '긴 이름이 모든 글자 보인다');
      final tags = tester.widget<PTagGroup>(
        find.descendant(of: row, matching: find.byType(PTagGroup)),
      );
      expect(tags.size, PTagGroupSize.t3);
      expect(tags.overflow, PTagGroupOverflow.truncate);
      expect(tester.getRect(row).right, 360);
    });

    testWidgets('묶음 합계 — 카드는 U+2212 · 중립색', (tester) async {
      await _pump(tester);
      final total = tester.widget<Text>(findPlain('−29,345,678원').last);
      expect(total.style?.color, PColors.light.fgNeutral);
      expect(total.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('묶음 카드가 가려지면 줄 금액이 모두 점', (tester) async {
      await _pump(tester, hidden: {'asset.cards'});
      // 요약(순자산 카드)의 지표 한 줄만 남는다 — 카드 묶음 합계 · 줄 · 막대 글은 모두 점
      expect(findPlain('−29,345,678원'), findsOneWidget);
      expect(findPlain('2,345,678원 초과'), findsNothing);
      expect(findPlainContaining('••••'), findsWidgets);
    });
  });

  group('56 · 한도 넘침 캡션 · 투자 등락 가림', () {
    testWidgets('넘친 카드 — 왼쪽 글이 남은 폭을 다 쓰고 "N원 초과" 가 줄 끝(336)에 선다', (
      tester,
    ) async {
      await _pump(tester);
      final left = findPlain('12,345,678원 / 10,000,000원');
      expect(left, findsOneWidget);
      final right = findPlain('2,345,678원 초과');
      expect(
        tester.getRect(right).right,
        336,
        reason: '오른쪽 글은 줄 끝에 선다(왼쪽 글 바로 뒤가 아니다)',
      );
      expect(
        tester.getRect(left).right,
        lessThan(tester.getRect(right).left),
        reason: '둘이 겹치지 않는다',
      );
      // 왼쪽 글은 오른쪽 글을 뺀 남은 폭을 다 쓴다 — 폭 절반에 갇히지 않는다(시험 글꼴은 넓어 한 줄 여부는 렌더로 본다)
      expect(
        tester.getSize(left).width,
        closeTo(312 - 8 - tester.getSize(right).width, 0.5),
        reason: '왼쪽 = 줄 폭 − 간격 8 − 오른쪽 글 폭',
      );
    });

    final val = {7: (value: 3500000, changeAmt: 12345)};
    String? deltaValue(WidgetTester t) =>
        t.widget<PDelta>(find.byKey(const ValueKey('asset-delta-7'))).value;

    testWidgets('가림 꺼짐 — 등락 줄이 보이고 값은 % (±금액)', (tester) async {
      await _pump(tester, valuation: val);
      expect(deltaValue(tester), contains('%'));
      expect(deltaValue(tester), contains('12,345원'));
    });

    testWidgets('투자 카드 가림 — 줄은 두고 값만 •••', (tester) async {
      await _pump(tester, valuation: val, hidden: {'asset.investments'});
      expect(find.byKey(const ValueKey('asset-delta-7')), findsOneWidget);
      expect(deltaValue(tester), '•••');
    });

    testWidgets('이 자산만 가림 — 줄은 두고 값만 •••', (tester) async {
      await _pump(
        tester,
        valuation: val,
        assets: () async => [
          _a(7, '주식 계좌', 'INVESTMENT', balance: 3000000, hidden: 'Y'),
        ],
      );
      expect(deltaValue(tester), '•••');
    });
  });

  group('57 · 순자산 추이 — 선 + 점, 채움 없음', () {
    testWidgets('점 12 · 영역 없음 · 계열 색 · 축 글자 U+2212', (tester) async {
      await _pump(tester);
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final bar = chart.data.lineBarsData.single;
      expect(bar.spots.length, 12);
      expect(bar.dotData.show, isTrue);
      expect(bar.belowBarData.show, isFalse);
      expect(bar.color, PColors.light.chartBlue);
      expect(find.textContaining('−'), findsWidgets);
    });

    testWidgets('차트 실패는 그 자리만 — 줄 · 목표는 그대로', (tester) async {
      await _pump(tester, trend: () async => throw Exception('x'));
      expect(findPlain('순자산 추이를 불러오지 못했어요'), findsOneWidget);
      expect(find.byType(PResultSection), findsOneWidget);
      expect(findPlain(_longName), findsOneWidget);
      expect(findPlain('저축 목표'), findsOneWidget);
    });
  });

  group('60 · 저축 목표 — 원까지', () {
    testWidgets('설명 줄 "{기한} · {현재 원} / {목표 원}" · 줄임 글 0 · 오른쪽 %', (
      tester,
    ) async {
      await _pump(tester);
      expect(
        findPlain('2028년 12월 · 1,234,567,890원 / 9,999,999,999원'),
        findsOneWidget,
      );
      expect(findPlain('기한 없음 · 100원 / 4,900원'), findsOneWidget);
      expect(find.textContaining('만'), findsNothing);
      expect(findPlain('12%'), findsOneWidget);
      expect(findPlain('달성'), findsWidgets, reason: '배지 + 막대 값 글');
    });
  });

  group('61 · 빈 화면', () {
    testWidgets('Result Section empty large + 첫 버튼 "계좌 · 카드 관리로 가기"', (
      tester,
    ) async {
      await _pump(tester, assets: () async => const []);
      final rs = tester.widget<PResultSection>(find.byType(PResultSection));
      expect(rs.kind, PResultKind.empty);
      expect(rs.size, PResultSize.large);
      expect(rs.primaryAction?.label, '계좌 · 카드 관리로 가기');
      expect(findPlain('아직 등록된 자산이 없어요'), findsOneWidget);
      expect(findPlain('설정 → 계좌 · 카드 관리에서 추가할 수 있어요.'), findsOneWidget);
      expect(_bands, findsOneWidget);
    });
  });

  group('62 · 카드마다 따로 불러오고 따로 실패', () {
    testWidgets('자산 목록 실패 — 질의 하나 = 상자 하나(요약 띠), 계좌 · 카드 띠는 없다', (
      tester,
    ) async {
      await _pump(tester, assets: () async => throw Exception('원문'));
      expect(findPlain('자산을 불러오지 못했어요'), findsOneWidget);
      expect(findPlain('순자산을 불러오지 못했어요'), findsNothing);
      expect(find.textContaining('원문'), findsNothing, reason: '오류 원문을 그리지 않는다');
      expect(findPlain('계좌 · 예금'), findsNothing);
      expect(
        findPlain('2028년 12월 · 1,234,567,890원 / 9,999,999,999원'),
        findsOneWidget,
      );
      expect(
        find.byType(PResultSection),
        findsNWidgets(1),
        reason: '요약 띠 하나 (추이 질의는 요약 실패 아래 그려지지 않는다)',
      );
    });

    testWidgets('저축 목표만 실패 — 자산은 그대로 · 그 띠만 실패', (tester) async {
      await _pump(tester, goals: () async => throw Exception('x'));
      expect(findPlain('저축 목표를 불러오지 못했어요'), findsOneWidget);
      expect(findPlain(_longName), findsOneWidget);
    });

    testWidgets('틀(머리 제목)은 늘 그리고 데이터 자리만 Skeleton', (tester) async {
      await _pump(
        tester,
        assets: () => Completer<List<Asset>>().future,
        goals: () => Completer<List<SavingGoal>>().future,
      );
      expect(findPlain('계좌 · 예금'), findsOneWidget);
      expect(findPlain('카드'), findsOneWidget);
      expect(findPlain('저축 목표'), findsOneWidget);
      expect(find.byType(PSkeleton), findsWidgets);
      expect(find.byType(PProgressBar), findsNothing);
    });
  });

  group('끝까지 닿기 · 200% · 다크', () {
    for (final scale in [1.0, 2.0]) {
      for (final mode in [Brightness.light, Brightness.dark]) {
        testWidgets('360 · 글자 ${scale * 100}% · $mode — 넘침 없음 · 줄은 화면 끝', (
          tester,
        ) async {
          await _pump(tester, textScale: scale, brightness: mode);
          expect(tester.takeException(), isNull);
          for (final e in find.byType(PListButtonItem).evaluate()) {
            final r = tester.getRect(find.byWidget(e.widget));
            expect(r.left, 0);
            expect(r.right, 360);
          }
          for (final e in find.byType(PProgressBar).evaluate()) {
            final r = tester.getRect(find.byWidget(e.widget));
            expect(r.left, 24, reason: '막대 왼쪽 가장자리 24');
            expect(r.right, 336, reason: '막대 오른쪽 가장자리 24');
          }
        });
      }
    }
  });
}
