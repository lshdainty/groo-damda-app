import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

import '../../support/real_fonts.dart';

const _flags = MaskFlags(
  card: false,
  expense: false,
  income: false,
  transfer: false,
);

// 11월 2일 −4,500 · 3일 −98,765 · 4일 −1,234,567 · 5일 +400,000,000 / 지출 −4,500
final _byDay = <String, ({int out, int inn})>{
  '2026-11-02': (out: 4500, inn: 0),
  '2026-11-03': (out: 98765, inn: 0),
  '2026-11-04': (out: 1234567, inn: 0),
  '2026-11-05': (out: 4500, inn: 400000000),
};

Future<void> _pump(
  WidgetTester t,
  double width,
  double scale, {
  MaskFlags flags = _flags,
  bool expanded = false,
}) async {
  t.view.physicalSize = Size(width, 800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: LedgerCalendar(
          month: DateTime(2026, 11),
          selected: '2026-11-02',
          expanded: expanded,
          byDay: _byDay,
          flags: flags,
          onSelect: (_) {},
          onToggleExpand: () {},
        ),
      ),
    ),
  );
  await t.pump();
}

String? _labelOf(WidgetTester t, String start) {
  final nodes = t.semantics.simulatedAccessibilityTraversal();
  for (final n in nodes) {
    if (n.label.startsWith(start)) return n.label;
  }
  return null;
}

void main() {
  setUpAll(loadRealFonts);
  for (final w in [360.0, 390.0, 430.0]) {
    for (final s in [1.0, 2.0]) {
      testWidgets('주 띠 칸 금액 — 폭 $w · 글자 ${s * 100}%: 온전히 쓰거나 점, 말줄임 0', (
        t,
      ) async {
        final handle = t.ensureSemantics();
        await _pump(t, w, s);
        expect(t.takeException(), isNull);
        final texts = [
          for (final e in find.byType(Text).evaluate()) (e.widget as Text),
        ];
        // 말줄임 글자 · 말줄임 설정 0
        expect(texts.where((x) => (x.data ?? '').contains('…')), isEmpty);
        expect(
          texts.where((x) => x.overflow == TextOverflow.ellipsis),
          isEmpty,
        );
        // 큰 금액은 100% · 200% 어느 폭에서도 칸에 안 들어간다 → 점, 일곱 자리 이상 글자가 칸에 남지 않는다
        expect(find.text('−1,234,567'), findsNothing);
        expect(find.text('+400,000,000'), findsNothing);
        expect(find.byKey(const ValueKey('ledger-cell-dot')), findsWidgets);
        // 글자 100% 에서 −4,500 은 온전히
        if (s == 1.0) expect(find.text('−4,500'), findsWidgets);
        if (s == 1.0 && w >= 390) expect(find.text('−98,765'), findsOneWidget);
        // 점이어도 칸 이름은 원까지
        expect(_labelOf(t, '11월 4일'), '11월 4일, 지출 1,234,567원');
        expect(_labelOf(t, '11월 5일'), '11월 5일, 지출 4,500원, 수입 400,000,000원');
        handle.dispose();
      });
    }
  }

  for (final w in [360.0, 390.0, 430.0]) {
    for (final s in [1.0, 2.0]) {
      testWidgets('펼친 월 격자 — 폭 $w · 글자 ${s * 100}%: 같은 점 규칙, 말줄임 0 · 넘침 0', (
        t,
      ) async {
        final handle = t.ensureSemantics();
        await _pump(t, w, s, expanded: true);
        expect(t.takeException(), isNull);
        final texts = [
          for (final e in find.byType(Text).evaluate()) (e.widget as Text),
        ];
        expect(texts.where((x) => (x.data ?? '').contains('…')), isEmpty);
        expect(
          texts.where((x) => x.overflow == TextOverflow.ellipsis),
          isEmpty,
        );
        expect(find.text('+400,000,000'), findsNothing);
        expect(find.byKey(const ValueKey('ledger-cell-dot')), findsWidgets);
        expect(_labelOf(t, '11월 4일'), '11월 4일, 지출 1,234,567원');
        handle.dispose();
      });
    }
  }

  testWidgets('줄 높이 불변 — 점이 있는 칸과 금액만 있는 칸의 금액 줄 높이가 같다', (t) async {
    await _pump(t, 390, 1);
    final dot = t
        .getSize(find.byKey(const ValueKey('ledger-cell-dot')).first)
        .height;
    final amount = t.getSize(find.text('−4,500').first).height;
    expect(dot, amount);
  });
}
