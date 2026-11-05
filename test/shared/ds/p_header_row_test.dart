// 머리 반 폭 판정 (I-04 03-G 결정 4A) — 오른쪽 동작이 머리 폭의 절반을 넘으면 제목 아래 줄 오른쪽 끝으로 간다.
//
// 새 공용 머리 셋(PCardHeader · PAccordionHeader · PListHeader)에만 건다. 옛 띠 머리(PFlatSection 등)는 건드리지 않는다
// (사용자 결정 2026-10-22). 평소(글자 100% · 130%)에는 한 줄 그대로다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/accordion/p_accordion.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/header_row/p_header_row.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';

Widget _app(Widget child, {double scale = 1, double width = 360}) =>
    MaterialApp(
      theme: GrooTheme.light(),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('PHeaderRow — 판정', () {
    Widget row(double actionWidth) => PHeaderRow(
      title: const SizedBox(key: ValueKey('t'), width: 40, height: 22),
      action: SizedBox(
        key: const ValueKey('a'),
        width: actionWidth,
        height: 36,
      ),
    );

    testWidgets('동작이 절반 − 간격 이하면 한 줄 — 동작은 오른쪽 끝, 세로 가운데', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_app(row(100), width: 300));
      final t = tester.getRect(find.byKey(const ValueKey('t')));
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      expect(a.right, 300);
      expect(a.top, lessThanOrEqualTo(t.top + 0.01));
      expect(tester.getSize(find.byType(PHeaderRow)).height, 36);
      expect((a.center.dy - t.center.dy).abs(), lessThan(0.01));
    });

    testWidgets('동작이 머리 폭의 절반을 넘으면 제목 아래 줄 오른쪽 끝 — 제목은 폭 전체', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_app(row(160), width: 300));
      final t = tester.getRect(find.byKey(const ValueKey('t')));
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      expect(a.top, closeTo(t.bottom + 8, 0.01), reason: '제목 아래 8');
      expect(a.right, 300, reason: '오른쪽 끝');
      expect(
        tester.getSize(find.byType(PHeaderRow)),
        const Size(300, 22 + 8 + 36),
      );
    });

    testWidgets('경계 — 절반 − 간격까지는 한 줄, 1 넘으면 내려간다', (tester) async {
      _viewport(tester);
      // 폭 300: 한 줄 한도 = 150 − 8 = 142
      await tester.pumpWidget(_app(row(142), width: 300));
      expect(tester.getSize(find.byType(PHeaderRow)).height, 36);
      await tester.pumpWidget(_app(row(143), width: 300));
      expect(tester.getSize(find.byType(PHeaderRow)).height, 22 + 8 + 36);
    });

    testWidgets('끝 블리드(−14)는 판정에서 동작 폭에서 뺀다 — 웹 `-mr-x3_5` 와 같다', (
      tester,
    ) async {
      _viewport(tester);
      Widget bleedRow(double actionWidth) => PHeaderRow(
        actionBleed: 14,
        title: const SizedBox(width: 40, height: 22),
        action: SizedBox(width: actionWidth, height: 36),
      );
      // 폭 300: 한 줄 한도 = 150 − 8 + 14 = 156
      await tester.pumpWidget(_app(bleedRow(156), width: 300));
      expect(tester.getSize(find.byType(PHeaderRow)).height, 36);
      await tester.pumpWidget(_app(bleedRow(157), width: 300));
      expect(tester.getSize(find.byType(PHeaderRow)).height, 22 + 8 + 36);
    });

    testWidgets('동작이 없으면 제목만', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        _app(
          PHeaderRow(
            title: const SizedBox(key: ValueKey('t'), width: 40, height: 22),
          ),
          width: 300,
        ),
      );
      expect(tester.getSize(find.byType(PHeaderRow)), const Size(300, 22));
    });
  });

  group('PListHeader — 동작이 줄 밖으로 번진 자리도 눌린다', () {
    for (final bleed in [14.0, 10.0]) {
      testWidgets('번짐 $bleed — 줄 끝 바깥 번짐 안쪽을 누르면 동작이 받는다', (tester) async {
        _viewport(tester);
        var taps = 0;
        await tester.pumpWidget(
          _app(
            PListHeader(
              title: '제목',
              actionBleed: bleed,
              action: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(
                  key: ValueKey('act'),
                  width: 36,
                  height: 36,
                ),
              ),
            ),
          ),
        );
        final r = tester.getRect(find.byKey(const ValueKey('act')));
        // 줄 끝(360 − 24 = 336)에서 번짐 − 2 만큼 바깥 점
        expect(r.right, closeTo(336 + bleed, 0.5));
        await tester.tapAt(Offset(336 + bleed - 2, r.center.dy));
        expect(taps, 1);
      });
    }
  });

  group('PListHeader flushAction — 동작이 줄 높이를 늘리지 않고 번진 자리도 눌린다', () {
    testWidgets('머리 36(위 8 + 글 20 + 아래 8) · 동작 위 번짐을 눌러도 받는다', (tester) async {
      _viewport(tester);
      var taps = 0;
      await tester.pumpWidget(
        _app(
          PListHeader(
            title: '제목',
            topInset: 8,
            flushAction: true,
            action: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox(
                key: ValueKey('act'),
                width: 36,
                height: 36,
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(PListHeader)).height, 36);
      final r = tester.getRect(find.byKey(const ValueKey('act')));
      expect(r.height, 36);
      await tester.tapAt(Offset(r.center.dx, r.top + 2));
      await tester.tapAt(Offset(r.center.dx, r.bottom - 2));
      expect(taps, 2);
    });
  });

  group('새 공용 머리 셋 — 100% 에서 한 줄, 200% 에서 내려간다', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('PCardHeader · 폭 360 · 글자 ${(scale * 100).round()}%', (
        tester,
      ) async {
        _viewport(tester);
        await tester.pumpWidget(
          _app(
            PCard(
              body: PCardBody.list,
              children: [
                PCardHeader(
                  title: '이번 달 지출',
                  actionLabel: '전체 보기',
                  onAction: () {},
                ),
              ],
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final title = tester.getRect(find.byKey(const ValueKey('card-title')));
        final box = tester.getRect(
          find.byKey(const ValueKey('text-button-box')),
        );
        if (scale < 1.5) {
          expect(box.center.dy, closeTo(title.center.dy, 1), reason: '한 줄');
        } else {
          expect(box.top, greaterThanOrEqualTo(title.bottom), reason: '내려갔다');
          // 머리 오른쪽 끝(글자 끝이 부모 여백 24 에 선다 — 상자는 14 바깥)
          expect(box.right, closeTo(360 - 24 + 14, 1));
        }
      });
    }

    for (final scale in [1.0, 2.0]) {
      testWidgets('PAccordionHeader · 폭 360 · 글자 ${(scale * 100).round()}%', (
        tester,
      ) async {
        _viewport(tester);
        await tester.pumpWidget(
          _app(
            PAccordionHeader(
              title: '혜택 상세 · 12건',
              trailing: PAccordionExpandAll(
                values: const [],
                expandable: const ['a'],
                onValuesChange: (_) {},
                expandLabel: '모두 펼치기',
                collapseLabel: '모두 접기',
              ),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final title = tester.getRect(
          find.byKey(const ValueKey('paccordion-header-title')),
        );
        final box = tester.getRect(
          find.byKey(const ValueKey('text-button-box')),
        );
        if (scale == 1) {
          expect(box.center.dy, closeTo(title.center.dy, 1));
        } else {
          expect(box.top, greaterThanOrEqualTo(title.bottom));
        }
      });
    }

    for (final scale in [1.0, 2.0]) {
      testWidgets('PListHeader · 폭 360 · 글자 ${(scale * 100).round()}%', (
        tester,
      ) async {
        _viewport(tester);
        await tester.pumpWidget(
          _app(
            PListHeader(
              title: '이번 주 거래',
              action: PTextButton(label: '전체 보기', onPressed: () {}),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final title = tester.getRect(
          find.byKey(const ValueKey('plist-header-title')),
        );
        final box = tester.getRect(
          find.byKey(const ValueKey('text-button-box')),
        );
        if (scale == 1) {
          expect(box.center.dy, closeTo(title.center.dy, 1));
        } else {
          expect(box.top, greaterThanOrEqualTo(title.bottom));
        }
      });
    }
  });
}
