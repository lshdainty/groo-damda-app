// 가계부 폰 옮기기 · 거르기 시트 · 조건 본문 부품(I-07 07-1 앱 몫).
//
// 화면을 실제로 띄워 값을 잰다 — 부품만 검사해 통과시키지 않는다(O 표). 고정한 오늘은 쓰지 않고 오늘 기준 상대 날짜로
// 데이터를 만든다(고정한 오늘 + 벽시계 = 시한폭탄).
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/domain/expense_filter.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_screen.dart';
import 'package:groo_damda_app/features/expense/presentation/filter_dialog.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/filter_bodies.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_day_group.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_filter_chips.dart';
import 'package:groo_damda_app/shared/ds/wheel_picker/p_wheel_picker.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/money/presentation/money_bundle_screen.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/transfer_row.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/scroll_auto_hide/p_scroll_auto_hide.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/widgets/p_card.dart';
import '../../support/plain_text.dart';

/// ds List 의 keepAll 이 글자 사이에 넣는 U+2060 · U+200B 를 뺀 글로 찾는다.
String _plain(String s) => s.replaceAll('\u2060', '').replaceAll('\u200B', '');

Finder _text(String s, {bool contains = false}) => find.byWidgetPredicate((w) {
  if (w is! Text) return false;
  final raw = _plain(w.data ?? w.textSpan?.toPlainText() ?? '');
  return contains ? raw.contains(s) : raw == s;
});

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 이번 달 1일의 오전 — 오늘보다 늘 앞이거나 같은 날(예정 거래가 되지 않는다).
String _stamp(int day) {
  final now = DateTime.now();
  return '${_ymd(DateTime(now.year, now.month, day))}T00:00:00';
}

Expense _tx(
  int id,
  String name,
  int amount, {
  String type = 'EXPENSE',
  String? auto,
  int day = 1,
  int categoryId = 1,
  int assetId = 1,
}) => Expense(
  rowId: id,
  expenseType: type,
  amount: amount,
  merchant: name,
  expenseDate: _stamp(day),
  categoryRowId: categoryId,
  categoryName: '식비',
  assetRowId: assetId,
  assetName: '월급 통장',
  autoSource: auto,
);

const _cats = [
  ExpenseCategory(rowId: 1, categoryName: '식비', expenseType: 'EXPENSE'),
  ExpenseCategory(rowId: 2, categoryName: '교통', expenseType: 'EXPENSE'),
];

const _assets = [
  Asset(rowId: 1, assetName: '월급 통장', assetType: 'BANK_ACCOUNT'),
  Asset(rowId: 2, assetName: '지갑', assetType: 'CASH'),
];

Future<void> _pump(
  WidgetTester tester, {
  Future<List<Expense>> Function(MonthKey key)? expenses,
  List<AssetTransfer> transfers = const [],
  String locale = 'ko',
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool disableAnimations = false,
  int? initialAssetId,
  String? initialMonth,
  Size size = const Size(360, 780),
  Set<String> hidden = const {},
}) async {
  tester.view.physicalSize = Size(size.width * 2, size.height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        hideCardProvider.overrideWith((ref, card) => hidden.contains(card)),
        categoriesProvider.overrideWith((ref) async => _cats),
        assetsProvider.overrideWith((ref) async => _assets),
        assetTransfersProvider.overrideWith((ref, key) async => transfers),
        monthExpensesProvider.overrideWith(
          (ref, key) =>
              expenses?.call(key) ??
              Future.value([
                _tx(1, '점심 가게', 12000, day: 1),
                _tx(2, '월급', 3000000, type: 'INCOME', day: 1),
              ]),
        ),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? GrooTheme.dark()
            : GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: ExpenseScreen(
            initialAssetId: initialAssetId,
            initialMonth: initialMonth,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

/// 숨는 영역(총액 · 지난달 비교 · 소비 요약)이 위로 옮겨진 거리.
double headerDyOf(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const ValueKey('pscrollautohide-header')))
    .transform
    .getTranslation()
    .y;

/// 필터 시트가 돌려준 값 — 시트를 닫은 뒤 본다.
ExpenseFilter? _result;

/// 실제 글꼴(Pretendard) — 시험 기본 글꼴(Ahem)은 글자마다 폭이 같고 줄바꿈 보호 글자(U+2060)도 폭이 있어 금액 폭 시험이 틀어진다.
Future<void> _loadRealFonts() async {
  final bytes = File('assets/fonts/PretendardVariable.ttf').readAsBytesSync();
  for (final family in ['Pretendard', 'FlutterTest']) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

/// 달 줄의 달 글을 눌러 연 | 월 휠 시트를 열고 [target] 달로 옮겨 "완료" 한다(‹ › 는 없다 — 10-29).
/// [settle] 이 false 면 마지막에 pumpAndSettle 을 쓰지 않는다(불러오는 중 스켈레톤이 계속 도는 화면).
Future<void> _pickMonth(
  WidgetTester tester,
  DateTime from,
  DateTime target, {
  bool settle = true,
}) async {
  await tester.tap(find.byIcon(LucideIcons.chevronDown).first);
  await tester.pumpAndSettle();
  Finder col(String name, String text) => find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is PWheelPickerColumn && w.semanticLabel == name,
    ),
    matching: findText(text),
  );
  if (target.year != from.year) {
    await tester.tap(col('연도', '${target.year}년').first);
    await tester.pumpAndSettle();
  }
  await tester.tap(col('월', '${target.month}월').first);
  await tester.pumpAndSettle();
  await tester.tap(findText('완료'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  setUpAll(_loadRealFonts);

  testWidgets('5 이체 줄 — 거래 줄과 글자 자리가 같고 타일은 회색 40', (tester) async {
    final now = DateTime.now();
    await _pump(
      tester,
      transfers: [
        AssetTransfer(
          rowId: 9,
          fromAssetRowId: 1,
          fromAssetName: '월급 통장',
          toAssetRowId: 2,
          toAssetName: '지갑',
          amount: 50000,
          description: '용돈 옮김',
          transferDate: '${_ymd(DateTime(now.year, now.month, 1))}T00:00:00',
        ),
      ],
    );
    final c = tester.element(find.byType(ExpenseScreen)).colors;
    final txTitle = tester.getTopLeft(_text('점심 가게')).dx;
    final trTitle = tester.getTopLeft(_text('용돈 옮김')).dx;
    expect(trTitle, closeTo(txTitle, 0.5), reason: '거래 줄 · 이체 줄 글자 x');
    // 금액 오른쪽 끝도 같다(둘 다 줄 끝 24)
    expect(
      tester.getTopRight(_text('50,000원', contains: true)).dx,
      closeTo(
        tester
            .getTopRight(
              find.byWidgetPredicate(
                (w) =>
                    w is Text &&
                    _plain(w.data ?? '').contains('12,000원') &&
                    w.style?.fontWeight == FontWeight.w700 &&
                    w.style?.fontSize == null,
              ),
            )
            .dx,
        0.5,
      ),
      reason: '거래 줄 · 이체 줄 금액 오른쪽 x',
    );
    final tile = find.byWidgetPredicate(
      (w) =>
          w.key == const ValueKey('plist-tile') &&
          w is DecoratedBox &&
          (w.decoration as BoxDecoration).color == c.chartGrayWeak,
    );
    expect(tile, findsOneWidget);
    expect(tester.getSize(tile), const Size(40, 40));
    final deco = tester.widget<DecoratedBox>(tile).decoration as BoxDecoration;
    expect(deco.color, c.chartGrayWeak);
    expect(deco.borderRadius, BorderRadius.circular(12));
    // 줄 끝에 ⋮ 가 없다(이체 줄도 거래 줄도)
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
  });

  testWidgets('6 줄 끝에 ⋮ 가 없다 — 수정 · 삭제 길은 밀기(시스템 거래는 밀기도 없다)', (tester) async {
    await _pump(
      tester,
      expenses: (_) async => [
        _tx(1, '점심 가게', 12000),
        _tx(2, '매도 손익', 90000, type: 'INCOME', auto: 'TRADE_PNL'),
      ],
    );
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    expect(find.byType(PSwipeActionsMore), findsNothing);
    // 밀기 틀은 일반 거래에만 — 시스템 거래는 없다
    expect(
      find.byWidgetPredicate((w) => w is PSwipeActions && w.actions.isNotEmpty),
      findsOneWidget,
    );
  });

  testWidgets('6 알림에서 들어온 줄은 bg-brand-weak 로 강조한다', (tester) async {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async => _cats),
          assetsProvider.overrideWith((ref) async => _assets),
          assetTransfersProvider.overrideWith((ref, key) async => const []),
          monthExpensesProvider.overrideWith(
            (ref, key) async => [_tx(1, '점심 가게', 12000)],
          ),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const Scaffold(body: ExpenseScreen(focusTxId: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 손으로 칠한 바탕이 아니라 ds List 의 `highlighted` 로 강조한다
    final row = find.byWidgetPredicate(
      (w) => w is PListButtonItem && w.highlighted,
    );
    expect(row, findsOneWidget);
    expect(tester.getRect(row).left, 0);
    expect(tester.getRect(row).right, 360, reason: '강조 바탕이 줄 끝(360)까지');
    final c = tester.element(find.byType(ExpenseScreen)).colors;
    expect(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == c.bgBrandWeak,
      ),
      findsNothing,
      reason: '화면이 같은 바탕을 직접 칠하지 않는다',
    );
  });

  testWidgets('7 거르기 단추에 개수 배지 · 켜짐 틴트가 없다 — 이름은 필터', (tester) async {
    await _pump(tester, initialAssetId: 1);
    expect(find.byType(PBadge), findsNothing);
    expect(find.bySemanticsLabel('필터'), findsWidgets);
  });

  testWidgets('8 소비 요약 ↔ 월 달력은 하나만 펼친다 · 요약에 카드가 없다', (tester) async {
    await _pump(tester);
    await tester.tap(findText('소비 요약'));
    await tester.pumpAndSettle();
    expect(_text('합계'), findsOneWidget);
    expect(find.byType(PCard), findsNothing);
    // 달력을 펼치면 요약이 접힌다(요약 줄 "합계" 가 사라진다)
    await tester.tap(find.bySemanticsLabel('월 달력'));
    await tester.pumpAndSettle();
    expect(_text('합계'), findsNothing);
    // 요약을 다시 펼치면 달력이 접힌다
    await tester.tap(findText('소비 요약'));
    await tester.pumpAndSettle();
    expect(_text('합계'), findsOneWidget);
  });

  testWidgets('11 오는 날은 불투명도 대신 fg-neutral-subtle · 펼침 이름은 월 달력 고정', (
    tester,
  ) async {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1, 1);
    await _pump(
      tester,
      initialMonth: '${next.year}-${next.month.toString().padLeft(2, '0')}',
      expenses: (_) async => const [],
    );
    final c = tester.element(find.byType(ExpenseScreen)).colors;
    // 접힌 상태 — 한 주. 다음 달은 모두 오는 날이다
    final dayTexts = find.descendant(
      of: find.byType(InkWell),
      matching: findText('1'),
    );
    expect(dayTexts, findsWidgets);
    final text = tester.widget<Text>(dayTexts.first);
    expect(text.style!.color, c.fgNeutralSubtle);
    expect(
      find.ancestor(of: dayTexts.first, matching: find.byType(Opacity)),
      findsNothing,
    );
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('월 달력'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('월 달력'));
    await tester.pumpAndSettle();
    // 펼쳐도 이름은 그대로
    expect(find.bySemanticsLabel('월 달력'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('고른 날 = 짙은 원(bg-neutral-inverted) · 브랜드 색 채움 없음', (tester) async {
    await _pump(tester, expenses: (_) async => const []);
    final c = tester.element(find.byType(ExpenseScreen)).colors;
    final decos = tester
        .widgetList<Container>(find.byType(Container))
        .map((w) => w.decoration)
        .whereType<BoxDecoration>();
    expect(decos.any((d) => d.color == c.bgNeutralInverted), isTrue);
    expect(decos.any((d) => d.color == c.bgBrandSolid), isFalse);
  });

  group('12 원장 머리 숨기기', () {
    final many = [for (var i = 1; i <= 12; i++) _tx(i, '가게 $i', 1000 * i)];

    double headerDy(WidgetTester tester) => tester
        .widget<Transform>(find.byKey(const ValueKey('pscrollautohide-header')))
        .transform
        .getTranslation()
        .y;

    testWidgets('내리면 머리가 위로 숨는다', (tester) async {
      await _pump(tester, expenses: (_) async => many);
      expect(find.byType(PScrollAutoHide), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pump();
      expect(headerDy(tester), lessThan(0));
    });

    testWidgets('모션 줄이기면 숨기지 않는다', (tester) async {
      await _pump(tester, expenses: (_) async => many, disableAnimations: true);
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pump();
      expect(headerDy(tester), 0);
    });
  });

  group('12 내려도 달 줄 · 주 달력 · 꺾쇠는 남고 고른 날이 목록을 따라간다', () {
    // 지난달(늘 다 지난 날) 1 ~ 28 일, 하루 두 건 — 여러 주에 걸친 긴 목록.
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    final prevQ = '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
    Expense on(int id, int day) => Expense(
      rowId: id,
      expenseType: 'EXPENSE',
      amount: 1000 + id,
      merchant: '가게 $id',
      expenseDate: '${_ymd(DateTime(prev.year, prev.month, day))}T09:00:00',
      categoryRowId: 1,
      categoryName: '식비',
      assetRowId: 1,
      assetName: '월급 통장',
    );
    final long = [
      for (var d = 1; d <= 28; d++) ...[on(d * 10, d), on(d * 10 + 1, d)],
    ];
    Future<List<Expense>> only(MonthKey k) async =>
        k.year == prev.year && k.month == prev.month ? long : const [];

    Finder grid() => find.byType(LedgerCalendarGrid);

    /// 주 달력에서 고른 날(짙은 원)의 숫자 — 없으면 null.
    int? selectedDay(WidgetTester tester) {
      final c = tester.element(find.byType(ExpenseScreen)).colors;
      final circle = find.descendant(
        of: grid(),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color == c.bgNeutralInverted,
        ),
      );
      if (circle.evaluate().isEmpty) return null;
      final t = tester.widget<Text>(
        find.descendant(of: circle.first, matching: find.byType(Text)).first,
      );
      return int.parse(t.data!);
    }

    /// 주 달력 한 줄에 보이는 날 숫자.
    Set<int> shownDays(WidgetTester tester) => {
      for (final t in tester.widgetList<Text>(
        find.descendant(of: grid(), matching: find.byType(Text)),
      ))
        ?int.tryParse(t.data ?? ''),
    };

    /// 남는 머리 아래(구분선 아래 끝)를 지난 묶음 중 가장 아래 = 지금 보는 날.
    int topGroupDay(WidgetTester tester) {
      final line = tester.getBottomLeft(find.byType(LedgerHeaderDivider)).dy;
      var best = double.negativeInfinity;
      var day = -1;
      for (final e in find.byType(LedgerDayGroup).evaluate()) {
        final top = tester.getTopLeft(find.byWidget(e.widget)).dy;
        if (top <= line + 28 && top > best) {
          best = top;
          day = (e.widget as LedgerDayGroup).date.day;
        }
      }
      return day;
    }

    testWidgets('내리면 총액만 숨고 달 줄 바로 아래에 주 달력 · 꺾쇠가 화면 안에 남는다', (tester) async {
      await _pump(tester, expenses: only, initialMonth: prevQ);
      final nav = find.byType(LedgerMonthNav);
      final navTop = tester.getTopLeft(nav).dy;
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(nav).dy, navTop, reason: '달 줄은 그 자리');
      expect(
        tester.getTopLeft(grid()).dy,
        moreOrLessEquals(tester.getBottomLeft(nav).dy, epsilon: 0.5),
        reason: '총액이 숨어 주 달력이 달 줄 바로 아래로 붙는다',
      );
      expect(tester.getBottomLeft(grid()).dy, lessThan(780));
      expect(
        tester.getTopLeft(find.byIcon(LucideIcons.chevronDown).last).dy,
        greaterThan(navTop),
        reason: '펼침 꺾쇠도 화면 안',
      );
      // 숨는 영역(총액)은 위로 옮겨졌다
      final h = tester.getSize(find.byType(LedgerTotalRow)).height;
      expect(headerDyOf(tester), moreOrLessEquals(-h, epsilon: 0.5));
    });

    testWidgets('내리는 대로 고른 날이 맨 위 날짜 묶음을 따라가고 다른 주로 넘어가면 주 달력도 바뀐다', (
      tester,
    ) async {
      await _pump(tester, expenses: only, initialMonth: prevQ);
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      final first = selectedDay(tester);
      expect(first, isNotNull);
      expect(first, topGroupDay(tester));
      expect(shownDays(tester), contains(first));
      final weekBefore = shownDays(tester);

      // 목록이 다른 주로 넘어간다(28 일에서 내려가 2 주 넘게)
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      final later = selectedDay(tester);
      expect(later, isNotNull);
      expect(later, topGroupDay(tester));
      expect(later, lessThan(first!));
      expect(shownDays(tester), contains(later));
      expect(shownDays(tester), isNot(weekBefore), reason: '주 달력이 그 주로 바뀐다');
    });

    testWidgets('날을 누르면 그 날 묶음이 남는 머리 바로 아래로 오고, 가는 동안 고른 날이 흔들리지 않는다', (
      tester,
    ) async {
      await _pump(tester, expenses: only, initialMonth: prevQ);
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      final cur = selectedDay(tester)!;
      // 같은 주에서 다른 날 — 고른 날보다 앞날(목록 아래쪽)
      final target = (shownDays(
        tester,
      ).where((d) => d < cur).toList()..sort()).first;
      await tester.tap(
        find.descendant(of: grid(), matching: find.text('$target')),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(selectedDay(tester), target, reason: '스파이가 잠겨 있다 (${i * 50}ms)');
      }
      await tester.pumpAndSettle();
      expect(selectedDay(tester), target);
      final line = tester.getBottomLeft(find.byType(LedgerHeaderDivider)).dy;
      final group = find.byWidgetPredicate(
        (w) => w is LedgerDayGroup && w.date.day == target,
      );
      expect(
        tester.getTopLeft(group).dy,
        moreOrLessEquals(line, epsilon: 1),
        reason: '주 달력 뒤로 들어가지 않고 그 바로 아래',
      );
    });

    testWidgets('필터 중에는 내려도 칩 줄이 달 줄 바로 아래 화면 안에 남는다', (tester) async {
      await _pump(
        tester,
        expenses: only,
        initialMonth: prevQ,
        initialAssetId: 1,
      );
      final chips = find.byType(LedgerFilterChips);
      expect(chips, findsOneWidget);
      final before = tester.getTopLeft(chips).dy;
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(chips).dy, before, reason: '칩 줄은 숨지 않는다');
      expect(
        tester.getTopLeft(chips).dy,
        moreOrLessEquals(
          tester.getBottomLeft(find.byType(LedgerMonthNav)).dy,
          epsilon: 0.5,
        ),
      );
    });

    for (final n in [3, 6, 9, 12]) {
      testWidgets('짧은 목록(하루 $n 건)에서 머리가 깜빡이지 않는다', (tester) async {
        await _pump(
          tester,
          expenses: (_) async => [
            for (var i = 1; i <= n; i++) _tx(i, '가게 $i', 1000 * i),
          ],
        );
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        final pos = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        final dy = headerDyOf(tester);
        final px = pos.pixels;
        final max = pos.maxScrollExtent;
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(headerDyOf(tester), dy);
          expect(pos.pixels, px);
          expect(pos.maxScrollExtent, max, reason: '숨겨도 목록 길이는 그대로');
        }
      });
    }
  });

  testWidgets('I-29b 4 펼침 단추 바로 아래가 구분선 · 그 아래 첫 묶음 위 4 에 날짜 머리(웹과 같은 y)', (
    tester,
  ) async {
    await _pump(tester);
    final btn = find.ancestor(
      of: find.byIcon(LucideIcons.chevronDown),
      matching: find.byType(PButton),
    );
    final btnBottom = tester.getBottomLeft(btn.first).dy;
    final divider = tester.getTopLeft(find.byType(LedgerHeaderDivider)).dy;
    expect(divider, btnBottom, reason: '단추 아래 여백 없음');
    final head = tester.getTopLeft(find.byType(PDayHeader).first).dy;
    expect(head, divider + 1 + 4, reason: '구분선 1 + 첫 묶음 위 4');
  });

  testWidgets('14 날짜 머리 — 머리말 2 · t4 · 500 · fg-neutral-subtle', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final c = tester.element(find.byType(ExpenseScreen)).colors;
    final head = find.byType(PDayHeader).first;
    final title = tester.widget<Text>(
      find
          .descendant(
            of: head,
            matching: find.byWidgetPredicate(
              (w) => w is Text && (w.data ?? '').contains('일 ('),
            ),
          )
          .first,
    );
    expect(title.style!.fontSize, 14);
    expect(title.style!.fontWeight, FontWeight.w500);
    expect(title.style!.color, c.fgNeutralSubtle);
    final node = tester.getSemantics(
      find.descendant(
        of: head,
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.headingLevel == 2,
        ),
      ),
    );
    expect(node.getSemanticsData().headingLevel, 2);
    // 그날 합계는 폰에서 그대로 둔다
    expect(findTextContaining('−12,000원'), findsWidgets);
    handle.dispose();
  });

  group('16 비어 있음 · 불러오기 · 실패', () {
    testWidgets('걸러서 0건 = funnel-x · 버튼 없음', (tester) async {
      await _pump(tester, initialAssetId: 1, expenses: (_) async => const []);
      expect(_text('조건에 맞는 거래가 없어요'), findsOneWidget);
      expect(find.byIcon(LucideIcons.funnelX), findsOneWidget);
      final section = find.byType(PResultSection);
      expect(
        find.descendant(of: section, matching: find.byType(TextButton)),
        findsNothing,
      );
      expect(
        tester.widget<PResultSection>(section).primaryAction,
        isNull,
        reason: '버튼 없음',
      );
    });

    testWidgets('이 달 0건 = 지금 글 · 버튼 없음', (tester) async {
      await _pump(tester, expenses: (_) async => const []);
      expect(_text('거래가 없어요', contains: true), findsOneWidget);
      expect(
        tester
            .widget<PResultSection>(find.byType(PResultSection))
            .primaryAction,
        isNull,
      );
    });

    testWidgets('실패에는 오류 원문을 그리지 않고 다시 시도만 둔다', (tester) async {
      await _pump(
        tester,
        expenses: (_) => Future.error(Exception('RAW_SERVER_TEXT_9137')),
      );
      expect(findTextContaining('RAW_SERVER_TEXT_9137'), findsNothing);
      final section = tester.widget<PResultSection>(
        find.byType(PResultSection),
      );
      expect(section.kind, PResultKind.failure);
      expect(section.primaryAction?.label, '다시 시도');
    });

    testWidgets('달을 옮길 때 달 이름이 먼저 바뀌고 화면 통째 스켈레톤으로 돌아가지 않는다', (tester) async {
      final pending = Completer<List<Expense>>();
      final now = DateTime.now();
      final cur = (year: now.year, month: now.month);
      await _pump(
        tester,
        expenses: (key) => key == cur
            ? Future.value([_tx(1, '점심 가게', 12000)])
            : pending.future,
      );
      expect(findText('${now.year}년 ${now.month}월'), findsWidgets);
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      await _pickMonth(tester, now, prevMonth, settle: false);
      // 달 이름은 바로 바뀌고, 머리 틀(Scroll Auto Hide · 달 이동 줄)은 그대로 있다
      expect(findText('${prevMonth.year}년 ${prevMonth.month}월'), findsWidgets);
      expect(find.byType(PScrollAutoHide), findsOneWidget);
      expect(find.byType(PSkeleton), findsWidgets);
      // 옛 달 숫자는 지운다
      expect(_text('점심 가게'), findsNothing);
      pending.complete(const []);
      await tester.pumpAndSettle();
    });
  });

  group('18 ~ 23 필터 시트와 조건 본문', () {
    Future<ExpenseFilter?> open(
      WidgetTester tester, {
      ExpenseFilter initial = const ExpenseFilter(),
      Brightness brightness = Brightness.light,
      double textScale = 1,
    }) async {
      tester.view.physicalSize = const Size(720, 1560);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      _result = null;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith((ref) async => _cats),
            assetsProvider.overrideWith((ref) async => _assets),
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
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    _result = await showFilterDialog(context, initial);
                  },
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(findText('열기'));
      await tester.pumpAndSettle();
      return _result;
    }

    testWidgets('조건이 하나 이하면 조건 맞추기 두 줄이 막힌다 · 안내가 뜬다', (tester) async {
      await open(tester);
      expect(findText('조건이 두 개 이상일 때 고를 수 있어요.'), findsOneWidget);
      expect(_text('모두 일치'), findsOneWidget);
      expect(_text('하나라도 일치'), findsOneWidget);
      expect(_text('걸린 조건을 모두 만족하는 거래만'), findsOneWidget);
    });

    testWidgets('빼고 로 바꾸면 고른 것이 exclude 로 옮겨 가고 섞이지 않는다', (tester) async {
      await open(tester);
      await tester.ensureVisible(findText('식비'));
      await tester.tap(findText('식비'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(findText('고른 것 빼고').first);
      await tester.tap(findText('고른 것 빼고').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(findText('교통'));
      await tester.tap(findText('교통'));
      await tester.pumpAndSettle();
      await tester.tap(findText('필터 적용'));
      await tester.pumpAndSettle();
      expect(findText('필터 적용'), findsNothing);
      // 넣기 · 빼기가 한 조건 안에서 섞이지 않는다 — 식비(넣기)가 빼기로 옮겨 가고 교통이 더해졌다
      expect(_result!.categories.include, isEmpty);
      expect(_result!.categories.exclude, {1, 2});
    });

    testWidgets('아무것도 안 고른 채 "고른 것 빼고" 를 먼저 누르면 그 모드로 남는다', (tester) async {
      await open(tester);
      await tester.ensureVisible(findText('고른 것 빼고').first);
      await tester.tap(findText('고른 것 빼고').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(findText('식비'));
      await tester.tap(findText('식비'));
      await tester.pumpAndSettle();
      await tester.tap(findText('필터 적용'));
      await tester.pumpAndSettle();
      expect(_result!.categories.include, isEmpty);
      expect(_result!.categories.exclude, {1});
    });

    testWidgets('기간 오류(시작 > 끝)면 필터 적용이 막힌다', (tester) async {
      await open(
        tester,
        initial: const ExpenseFilter(
          periods: [
            FilterPeriodRange(
              preset: FilterPeriodPreset.custom,
              start: '2026-10-20',
              end: '2026-10-01',
            ),
          ],
        ),
      );
      expect(findText('시작일이 종료일보다 늦을 수 없어요.'), findsOneWidget);
      await tester.tap(findText('필터 적용'));
      await tester.pumpAndSettle();
      // 막혀서 시트가 그대로 열려 있다
      expect(findText('필터 적용'), findsOneWidget);
    });

    testWidgets('거래 종류 둘 다 끄면 전체 — 칩 줄에 엉뚱한 수입 칩이 생기지 않는다', (tester) async {
      await open(tester);
      for (final name in ['지출', '수입']) {
        await tester.ensureVisible(findText(name).first);
        await tester.pumpAndSettle();
        await tester.tap(findText(name).first);
        await tester.pumpAndSettle();
      }
      await tester.tap(findText('필터 적용'));
      await tester.pumpAndSettle();
      expect(findText('필터 적용'), findsNothing);
      // 둘 다 끄면 둘 다 켠 것과 같다 — 빈 집합을 내보내지 않는다(= 종류 조건 없음)
      expect(_result!.types, {'EXPENSE', 'INCOME'});
      expect(activeConditionCount(_result!), 0);
    });

    testWidgets('조건 본문의 List 줄이 시트 폭(360) 끝까지 간다', (tester) async {
      await open(tester);
      final rows = find.descendant(
        of: find.byType(PBottomSheetContent),
        matching: find.byWidgetPredicate((w) => w is PListItemBase),
      );
      expect(rows, findsWidgets, reason: '조건 줄이 있어야 잰다');
      for (var i = 0; i < rows.evaluate().length; i++) {
        final r = tester.getRect(rows.at(i));
        expect(r.left, 0, reason: '조건 줄 $i 왼쪽');
        expect(r.right, 360, reason: '조건 줄 $i 오른쪽 = 화면 폭');
      }
    });

    testWidgets('본문이 넘치면 본문만 스크롤하고 200% 에서도 넘침 오류가 없다', (tester) async {
      await open(tester, textScale: 2, brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find
            .descendant(
              of: find.byType(PBottomSheetContent),
              matching: find.byType(SingleChildScrollView),
            )
            .first,
        const Offset(0, -600),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('11 합계 줄 제목만 700 · 7 소비 요약 위 8', (tester) async {
    await _pump(tester);
    await tester.tap(findText('소비 요약'));
    await tester.pumpAndSettle();
    FontWeight? weightOf(String t) => tester
        .widget<Text>(
          find.descendant(of: find.byType(Scaffold), matching: _text(t)).first,
        )
        .style
        ?.fontWeight;
    expect(weightOf('합계'), FontWeight.w700);
    expect(weightOf('지출'), FontWeight.w400);
  });

  testWidgets('15 · 47 칸 금액은 가림 "••" · 빼기는 U+2212', (tester) async {
    await _pump(tester);
    // 접힌 주 달력 — 오늘이 든 주의 칸 금액(오늘 거래가 없으면 이번 달 1일 거래는 월 달력에서)
    await tester.tap(find.bySemanticsLabel('월 달력'));
    await tester.pumpAndSettle();
    expect(findTextContaining('-1', findRichText: true), findsNothing);
    expect(findTextContaining('−', findRichText: true), findsWidgets);
    expect(_text('−12,000', contains: true), findsWidgets);
  });

  testWidgets('자산 거르기(?assetId)는 목록을 그 자산 거래로 거른다', (tester) async {
    await _pump(
      tester,
      initialAssetId: 2,
      expenses: (_) async => [
        _tx(1, '월급 통장 결제', 12000, assetId: 1),
        _tx(2, '지갑 결제', 3000, assetId: 2),
      ],
    );
    expect(_text('지갑 결제'), findsOneWidget);
    expect(_text('월급 통장 결제'), findsNothing);
  });

  testWidgets('빈 달에도 지난달 이용 내역 보기 단추가 있다', (tester) async {
    await _pump(tester, expenses: (_) async => const []);
    expect(findTextContaining('이용 내역 보기'), findsOneWidget);
  });

  testWidgets('실패에는 설명 글이 있다', (tester) async {
    await _pump(tester, expenses: (_) => Future.error(Exception('x')));
    expect(
      tester.widget<PResultSection>(find.byType(PResultSection)).description,
      '잠시 뒤 다시 시도해주세요.',
    );
  });

  testWidgets('영어 "Delete" 밀기 라벨도 한 줄 — 칸이 글 폭만큼 넓어진다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: Scaffold(
          body: PSwipeActions(
            actions: [
              PSwipeAction(
                label: 'Delete',
                kind: PSwipeActionKind.destructive,
                icon: LucideIcons.trash2,
                onSelect: () {},
              ),
            ],
            child: const SizedBox(height: 64, width: double.infinity),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final label = tester.getSize(
      find.byKey(const ValueKey('swipe-label-Delete')),
    );
    expect(label.height, lessThan(20), reason: '한 줄');
    expect(swipeSlotWidth(0), 56, reason: '한글 두 글자 칸은 그대로');
  });

  testWidgets('가림: 거래 목록 카드만 켜도 달력 칸 금액은 "••" (툴팁이 같은 금액을 말한다)', (
    tester,
  ) async {
    await _pump(tester, hidden: {'ledger.txList'});
    await tester.tap(find.bySemanticsLabel('월 달력'));
    await tester.pumpAndSettle();
    expect(findTextContaining('−••'), findsWidgets);
  });

  testWidgets('가림: 월 합계 카드를 켜면 인사이트 금액도 가린다', (tester) async {
    final now = DateTime.now();
    final cur = (year: now.year, month: now.month);
    await _pump(
      tester,
      hidden: {'ledger.monthSummary'},
      expenses: (key) async =>
          key == cur ? [_tx(1, '이번 달 가게', 100000)] : [_tx(2, '지난달 가게', 400000)],
    );
    // 가림 점은 krw.dart 기본 마스크 6개
    expect(_text('••••••', contains: true), findsWidgets);
    expect(_text('만원', contains: true), findsNothing);
  });

  testWidgets('폰 기간 시트의 빠른 기간은 이번 주 · 이번 달 · 3개월 — 넓은 기간은 없다', (tester) async {
    await _pump(tester);
    await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(PInputButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PInputButton).first);
    await tester.pumpAndSettle();
    final names = PDatePickerLabels.ko.presetNames;
    expect(findText(names[PDatePreset.thisWeek]!), findsOneWidget);
    expect(findText(names[PDatePreset.thisMonth]!), findsOneWidget);
    expect(findText(names[PDatePreset.last3Months]!), findsOneWidget);
    expect(findText(names[PDatePreset.lastMonth]!), findsNothing);
    expect(findText(names[PDatePreset.thisYear]!), findsNothing);
  });

  testWidgets('글자 200% — 두 자리 날 숫자 원이 글을 따라 늘어 잘리지 않는다', (tester) async {
    await _pump(tester, textScale: 2, expenses: (_) async => const []);
    await tester.tap(find.bySemanticsLabel('월 달력'), warnIfMissed: false);
    await tester.pumpAndSettle();
    final text = findText('18').first;
    final circle = find
        .ancestor(of: text, matching: find.byType(Container))
        .first;
    expect(
      tester.getSize(circle).width,
      greaterThanOrEqualTo(tester.getSize(text).width + 8 - 0.5),
      reason: '좌우 4 + 글 폭 이상',
    );
    expect(tester.getSize(circle).width, greaterThanOrEqualTo(36));
    // 글자를 줄이지 않는다 — 크기를 줄이는 FittedBox · Transform 이 원 위에 없다(웹처럼 넘치기만 한다)
    expect(
      find.ancestor(of: circle, matching: find.byType(FittedBox)),
      findsNothing,
    );
    expect(
      tester.getSize(text).height,
      greaterThan(35),
      reason: '글자는 200% 크기 그대로(t5 16 → 32)',
    );
  });

  testWidgets('거래 줄 — ⋮ 없음 · 금액 끝 336(줄 끝 24) · 줄 0~360', (tester) async {
    await _pump(tester, expenses: (_) async => [_tx(1, '점심 가게', 12000)]);
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    final row = tester.getRect(find.byType(PListButtonItem).first);
    expect(row.left, 0);
    expect(row.right, 360);
    final amount = tester.getRect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            _plain(w.data ?? '') == '−12,000원' &&
            w.style?.fontWeight == FontWeight.w700 &&
            w.style?.fontSize == null,
      ),
    );
    expect(amount.right, closeTo(360 - 24, 0.5), reason: '금액 끝 = 줄 끝 24');
  });

  testWidgets('자산 이름이 길어도 카테고리는 줄지 않는다(자산 이름이 먼저 준다)', (tester) async {
    await _pump(
      tester,
      expenses: (_) async => [
        _tx(1, '가게', 12000).copyWith(
          categoryRowId: null,
          categoryName: '주거 · 관리비 · 공과금',
          assetName: '아주 길고 긴 이름의 통장 별칭입니다 정말로 길어요 길어요',
        ),
      ],
    );
    final cat = _text('주거 · 관리비 · 공과금', contains: true);
    expect(cat, findsOneWidget);
    // 글 폭이 그대로(13px 에서 약 90) — 한 글자 + … 로 줄지 않았다
    expect(tester.getSize(cat).width, greaterThan(70));
  });

  test('폰 빠른 기간의 범위는 ds 정의(달력 단위)를 따른다 — 이름은 이번 주 · 이번 달 · 3개월', () {
    expect(kFilterPeriodPresets, [
      PDatePreset.thisWeek,
      PDatePreset.thisMonth,
      PDatePreset.last3Months,
    ]);
    // 2026-10-23(금) 기준
    final today = DateTime(2026, 10, 23);
    final week = getPresetRange(PDatePreset.thisWeek, today);
    expect(week.start, DateTime(2026, 10, 18), reason: '일요일 시작');
    expect(week.end, DateTime(2026, 10, 24), reason: '토요일 끝(앞으로의 날도 든다)');
    final month = getPresetRange(PDatePreset.thisMonth, today);
    expect(month.start, DateTime(2026, 10, 1));
    expect(month.end, DateTime(2026, 10, 31), reason: '이달 말일까지(옛 폰은 오늘까지)');
    final three = getPresetRange(PDatePreset.last3Months, today);
    expect(three.start, DateTime(2026, 8, 1), reason: '두 달 전 1일');
    expect(three.end, DateTime(2026, 10, 31));
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('요약 줄 · 머리 아래 선 · 목록 줄이 화면 끝(360)까지 간다 — 글자 x$scale', (
      tester,
    ) async {
      await _pump(tester, textScale: scale);
      await tester.tap(findText('소비 요약'));
      await tester.pumpAndSettle();
      // 요약 줄 셋(수입 · 지출 · 합계)
      final items = find.descendant(
        of: find.byType(LedgerSummaryList),
        matching: find.byType(PListItem),
      );
      expect(items, findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        final r = tester.getRect(items.at(i));
        expect(r.left, 0, reason: '요약 줄 $i 왼쪽');
        expect(r.right, 360, reason: '요약 줄 $i 오른쪽 = 화면 폭');
      }
      // 머리 아래 선
      final line = tester.getRect(find.byType(LedgerHeaderDivider));
      expect(line.left, 0);
      expect(line.right, 360, reason: '머리 아래 선 오른쪽 = 화면 폭');
      // 목록 줄(거래 줄 · 날짜 머리) — 200% 에서는 요약이 화면을 채워 목록이 아직 만들어지지 않는다
      if (scale > 1) return;
      final row = tester.getRect(find.byType(PListButtonItem).first);
      expect(row.left, 0);
      expect(row.right, 360, reason: '목록 줄 오른쪽 = 화면 폭');
      final head = tester.getRect(find.byType(PDayHeader).first);
      expect(head.right, 360, reason: '날짜 머리 오른쪽 = 화면 폭');
    });
  }

  testWidgets('이체 줄 · 밀어 연 줄도 화면 끝(360)까지 간다 — 거래 줄과 같다', (tester) async {
    final now = DateTime.now();
    await _pump(
      tester,
      transfers: [
        AssetTransfer(
          rowId: 9,
          fromAssetRowId: 1,
          fromAssetName: '월급 통장',
          toAssetRowId: 2,
          toAssetName: '지갑',
          amount: 50000,
          description: '용돈 옮김',
          transferDate: '${_ymd(DateTime(now.year, now.month, 1))}T00:00:00',
        ),
      ],
    );
    final tr = tester.getRect(find.byType(TransferRow));
    expect(tr.left, 0, reason: '이체 줄 왼쪽');
    expect(tr.right, 360, reason: '이체 줄 오른쪽 = 화면 폭');
    final trItem = tester.getRect(
      find
          .descendant(
            of: find.byType(TransferRow),
            matching: find.byWidgetPredicate((w) => w is PListItemBase),
          )
          .first,
    );
    expect(trItem.left, 0);
    expect(trItem.right, 360, reason: '이체 ds List 줄 오른쪽 = 화면 폭');
    final tx = tester.getRect(find.byType(PListButtonItem).first);
    expect(trItem.right, tx.right, reason: '거래 줄과 같은 끝');
    // 금액 오른쪽 끝(거래 줄과 같이 줄 끝 24)
    final amount = tester.getTopRight(_text('50,000원', contains: true)).dx;
    expect(amount, closeTo(360 - 24, 0.5), reason: '이체 금액 끝 = 거래 줄과 같은 24');
    // 밀어 연 거래 줄: 틀은 화면 폭 그대로, 열린 행동 칸이 보이고 그 오른쪽 끝이 화면 끝(360)
    final swipe = find.byType(PSwipeActions).first;
    expect(tester.getRect(swipe).left, 0);
    expect(tester.getRect(swipe).right, 360, reason: '밀기 틀(닫힘)');
    final row = find
        .descendant(
          of: swipe,
          matching: find.byKey(const ValueKey('swipe-row')),
        )
        .first;
    final content = find
        .descendant(of: swipe, matching: find.byType(PListButtonItem))
        .first;
    expect(tester.getRect(content).left, 0, reason: '닫힌 줄은 제자리');
    final g = await tester.startGesture(tester.getCenter(row));
    for (var i = 0; i < 8; i++) {
      await g.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getRect(content).left, lessThan(0), reason: '줄이 밀려 열렸다');
    final tray = tester.getRect(
      find
          .descendant(
            of: swipe,
            matching: find.byKey(const ValueKey('swipe-tray')),
          )
          .first,
    );
    expect(tray.width, greaterThan(0), reason: '열린 행동 칸이 보인다');
    expect(tray.right, 360, reason: '열린 행동 칸 오른쪽 끝 = 화면 끝');
    expect(
      tester.getRect(content).right,
      closeTo(tray.left, 1),
      reason: '밀린 줄의 끝이 행동 칸 시작',
    );
    expect(tester.getRect(swipe).right, 360, reason: '밀기 틀(열림)');
  });

  group('200% · 다크 — 가장 나쁜 값에서 넘침 오류가 없다', () {
    final worst = [
      _tx(1, '아주 길고 긴 이름의 온라인 종합 쇼핑몰 본점 가장 긴 가맹점 이름', 1234567890),
      _tx(2, '월급', 450000000, type: 'INCOME'),
      for (var i = 3; i <= 10; i++) _tx(i, '가게 $i', 1000 * i),
    ];

    testWidgets('360 · 100% 최악값 금액은 쉼표 뒤에서 접히고 카테고리는 줄지 않는다(값 길이로 내리지 않는다)', (
      tester,
    ) async {
      await _pump(
        tester,
        expenses: (_) async => [
          _tx(1, '가게', 1234567890).copyWith(
            categoryRowId: null,
            categoryName: '주거·통신 및 공과금 정기결제',
            assetName: '하늘은행 월급 통장',
          ),
        ],
      );
      expect(tester.takeException(), isNull);
      final amount = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            _plain(w.data ?? '') == '−1,234,567,890원' &&
            w.style?.fontWeight == FontWeight.w700 &&
            w.style?.fontSize == null,
      );
      expect(amount, findsOneWidget);
      // 값은 옆에 남고(ds 가 줄 안 폭 16em 미만일 때만 내린다) 쉼표 뒤에서 접힌다
      final title = _text('가게');
      expect(
        tester.getTopLeft(amount).dx,
        greaterThan(tester.getTopRight(title).dx - 1),
      );
      final category = _text('주거·통신 및 공과금 정기결제', contains: true);
      expect(tester.getSize(category).width, greaterThan(70));
    });

    // 가장 나쁜 값 −1,234,567,890원 — 쉼표 뒤에서만 줄을 바꿔 넘치지 않는다(03-D 결정 2 B). 200% 는 줄 안 폭 16em 미만이라
    // 값이 본문 아래로 접힌다(03-D 결정 1 B).
    for (final scale in [1.0, 2.0]) {
      testWidgets('x$scale 가계부 · 소비 요약 · 월 달력', (tester) async {
        final errors = <FlutterErrorDetails>[];
        final prev = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = prev);
        await _pump(
          tester,
          expenses: (_) async => worst,
          textScale: scale,
          brightness: Brightness.dark,
        );
        await tester.tap(find.bySemanticsLabel('월 달력'), warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(findText('소비 요약'), warnIfMissed: false);
        await tester.pumpAndSettle();
        FlutterError.onError = prev;
        final mine = errors
            .map((d) => d.exceptionAsString().split('\n').first)
            .toList();
        expect(
          mine,
          isEmpty,
          reason: errors
              .map((d) => d.toString().split('\n').take(12).join(' | '))
              .join('\n'),
        );
      });
    }
  });

  testWidgets('13 가계부 묶음 1차 Line 탭은 화면을 내려도 상단에 남는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: MoneyBundleScreen(
            tab: MoneyTab.expense,
            pages: [
              ListView(children: [for (var i = 0; i < 60; i++) Text('줄 $i')]),
              const SizedBox(),
              const SizedBox(),
              const SizedBox(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.byType(PTabs<MoneyTab>));
    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(PTabs<MoneyTab>)), before);
  });
}
