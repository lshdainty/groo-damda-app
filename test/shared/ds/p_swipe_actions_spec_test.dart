// Swipe Actions 가 스펙 값(test/fixtures/design_spec/swipe-actions.json)대로인지 — 종류 × 상태 × 라이트 · 다크로 동작 칸을 재고,
// 판정(데드존 · 축 · 문턱 · 최대 이동) · 한 번에 한 줄 · 스크롤 닫힘 · 탭 삼키기 · 접근성 · ⋮ 를 따로 본다. 웹은 같은 JSON 을
// 크로미움에서 잰다. 앱에 없는 상태(hovered · focused — 웹 상태)는 건너뛴다.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('swipe-actions');

Widget _host(
  Brightness mode,
  Widget child, {
  bool reduceMotion = false,
  TextDirection direction = TextDirection.ltr,
  double width = 360,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

const _kinds = {
  'neutral': PSwipeActionKind.neutral,
  'primary': PSwipeActionKind.primary,
  'destructive': PSwipeActionKind.destructive,
};

PSwipeAction _action(
  PSwipeActionKind kind, {
  String? label,
  bool disabled = false,
  VoidCallback? onSelect,
}) => PSwipeAction(
  kind: kind,
  label:
      label ??
      switch (kind) {
        PSwipeActionKind.neutral => '고정',
        PSwipeActionKind.primary => '수정',
        PSwipeActionKind.destructive => '삭제',
      },
  icon: LucideIcons.pin,
  disabled: disabled,
  onSelect: onSelect ?? () {},
);

PColors _colors(Brightness mode) =>
    mode == Brightness.dark ? PColors.dark : PColors.light;

void _expectColor(Object? want, Brightness mode, Color actual, String why) {
  expect(
    sameColor(specColor(pickMode(want, mode)), actual),
    isTrue,
    reason: '$why 기대 ${pickMode(want, mode)} 실제 ${colorHex(actual)}',
  );
}

double _offset(WidgetTester tester, [int i = 0]) {
  final box = tester.widget<AnimatedContainer>(
    find.byKey(const ValueKey('swipe-row')).at(i),
  );
  final m = box.transform;
  return m == null ? 0 : m.getTranslation().x;
}

/// 줄 — 높이 64 · 폭 360. 누르면 [taps] 가 는다.
class _Row extends StatelessWidget {
  const _Row(this.title, {required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(height: 64, child: Text(title)),
  );
}

void main() {
  group('판정 값', () {
    test('트레이 폭은 하나 56 · 둘 104 · 셋 152, 칸 폭은 첫 칸 56 · 다음부터 48', () {
      expect(swipeSlotWidth(0), 56);
      expect(swipeSlotWidth(1), 48);
      expect(swipeSlotWidth(2), 48);
      expect(swipeTrayWidth(1), 56);
      expect(swipeTrayWidth(2), 104);
      expect(swipeTrayWidth(3), 152);
    });

    test('축 — 데드존 8 안은 판정하지 않고, 1.5배 넘어야 가로', () {
      expect(resolveSwipeAxis(5, 5), PSwipeAxis.none);
      expect(resolveSwipeAxis(7.9, 0), PSwipeAxis.none);
      expect(resolveSwipeAxis(8, 0), PSwipeAxis.x);
      expect(resolveSwipeAxis(-31, 20), PSwipeAxis.x);
      expect(
        resolveSwipeAxis(-30, 20),
        PSwipeAxis.y,
        reason: "정확히 1.5배는 가로가 아니다",
      );
      expect(resolveSwipeAxis(-30, 20.1), PSwipeAxis.y);
      expect(resolveSwipeAxis(0, 9), PSwipeAxis.y);
      expect(resolveSwipeAxis(10, 10), PSwipeAxis.y);
    });

    test('열기 40% · 닫기 25% — 문턱이 서로 다르다', () {
      const tray = 104.0;
      expect(settleSwipeOpen(false, tray * 0.4 - 0.1, tray), isFalse);
      expect(settleSwipeOpen(false, tray * 0.4, tray), isTrue);
      // 열려 있던 줄은 25% 미만만 되돌려도 열린 채
      expect(settleSwipeOpen(true, tray - tray * 0.25 + 0.1, tray), isTrue);
      expect(settleSwipeOpen(true, tray - tray * 0.25, tray), isFalse);
      // 같은 위치(60%)에서 닫혀 있던 줄은 열리고, 열려 있던 줄은 닫힌다 — 두 문턱이 맞물리지 않는다
      expect(settleSwipeOpen(false, tray * 0.6, tray), isTrue);
      expect(settleSwipeOpen(true, tray * 0.6, tray), isFalse);
    });

    test('최대 이동 — 트레이 폭에서 멈추고, 반대로 밀면 0', () {
      expect(clampSwipeOffset(500, 104), 104);
      expect(clampSwipeOffset(-40, 104), 0);
      expect(clampSwipeOffset(50, 104), 50);
    });
  });

  for (final mode in Brightness.values) {
    for (final kindName in _kinds.keys) {
      for (final state in ['enabled', 'pressed', 'disabled']) {
        testWidgets('$kindName · $state · ${mode.name} — 동작 칸이 스펙 값이다', (
          tester,
        ) async {
          final kind = _kinds[kindName]!;
          final want = _spec.resolve({
            'kind': kindName,
            'size': 'default',
          }, state);
          final c = _colors(mode);
          final disabled = state == 'disabled';
          await tester.pumpWidget(
            _host(
              mode,
              Row(
                children: [
                  PSwipeActionCell(
                    action: _action(kind, disabled: disabled),
                    rowLabel: '스타벅스',
                    previewPressed: state == 'pressed',
                  ),
                ],
              ),
            ),
          );

          // 배지 — 36 원, 색은 배지만
          final badgeBox = tester.getRect(
            find.byKey(const ValueKey('swipe-badge')),
          );
          expect(badgeBox.width, (want['badge.size'] as num).toDouble());
          expect(badgeBox.height, (want['badge.size'] as num).toDouble());
          final deco =
              tester
                      .widget<Container>(
                        find.byKey(const ValueKey('swipe-badge')),
                      )
                      .decoration!
                  as BoxDecoration;
          expect(deco.shape, BoxShape.circle, reason: '배지 모서리 9999');
          final roles = resolveSwipeColors(c, kind: kind, disabled: disabled);
          _expectColor(want['badge.background'], mode, deco.color!, '배지 바탕');
          expect(deco.color, roles.badge);
          if (want['badge.borderWidth'] != null) {
            final border = deco.border! as Border;
            expect(
              border.top.width,
              (want['badge.borderWidth'] as num).toDouble(),
            );
            _expectColor(
              want['badge.borderColor'],
              mode,
              border.top.color,
              '배지 테두리',
            );
            // 안쪽 1px — 배지 지름이 그대로다
            expect(border.top.strokeAlign, BorderSide.strokeAlignInside);
          } else {
            expect(deco.border, isNull);
          }

          // 아이콘 — 18 · 색
          final icon = tester.widget<Icon>(
            find.descendant(
              of: find.byKey(const ValueKey('swipe-badge')),
              matching: find.byType(Icon),
            ),
          );
          expect(icon.size, (want['icon.size'] as num).toDouble());
          _expectColor(want['icon.color'], mode, icon.color!, '아이콘');

          // 라벨 — 12 / 700 / 1.3 · 색
          final label = tester.widget<Text>(
            find.byKey(ValueKey('swipe-label-${_action(kind).label}')),
          );
          final typo = (want['label.typography'] as Map)
              .cast<String, dynamic>();
          expect(label.style!.fontSize, typo['fontSize']);
          expect(label.style!.fontWeight!.value, want['label.fontWeight']);
          expect(
            label.style!.height,
            (want['label.lineHeight'] as num).toDouble(),
          );
          _expectColor(want['label.color'], mode, label.style!.color!, '라벨');

          // 칸 — 폭 56(첫 칸) · 높이 56 이상 · 배지 ↔ 라벨 2 · 앞 간격 20
          final cell = tester.getRect(
            find.byKey(ValueKey('swipe-action-${_action(kind).label}')),
          );
          expect(cell.width, 56);
          expect(cell.height, greaterThanOrEqualTo(56));
          final labelRect = tester.getRect(
            find.byKey(ValueKey('swipe-label-${_action(kind).label}')),
          );
          expect(
            labelRect.top - badgeBox.bottom,
            (want['action.gap'] as num).toDouble(),
          );
          expect(badgeBox.left - cell.left, 20);
          expect(cell.right - badgeBox.right, 0, reason: '뒤에는 간격이 없다');

          // 누름 — 밝기 88% 만, 움직이지 않는다. 막힌 칸은 그대로
          final dim = find.byKey(const ValueKey('swipe-action-dim'));
          expect(dim, state == 'pressed' ? findsOneWidget : findsNothing);
          expect(
            tester.getRect(
              find.byKey(ValueKey('swipe-action-${_action(kind).label}')),
            ),
            cell,
          );
        });
      }
    }
  }

  testWidgets('손가락으로 누르는 동안 밝기 88% — 움직이지 않고, 떼면 돌아온다', (tester) async {
    await tester.pumpWidget(
      _host(
        Brightness.light,
        Row(
          children: [
            PSwipeActionCell(action: _action(PSwipeActionKind.primary)),
          ],
        ),
      ),
    );
    final before = tester.getRect(
      find.byKey(const ValueKey('swipe-action-수정')),
    );
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('swipe-action-수정'))),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('swipe-action-dim')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('swipe-action-수정'))),
      before,
    );
    await g.up();
    await tester.pump();
    expect(find.byKey(const ValueKey('swipe-action-dim')), findsNothing);
  });

  testWidgets('칸 폭은 둘째 칸부터 48 · 앞 간격 12, 높이는 줄을 따른다(줄이 높으면 그만큼)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Brightness.light,
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PSwipeActionCell(
                    action: _action(PSwipeActionKind.destructive),
                    index: 0,
                  ),
                  PSwipeActionCell(
                    action: _action(PSwipeActionKind.primary),
                    index: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final del = tester.getRect(find.byKey(const ValueKey('swipe-action-삭제')));
    final edit = tester.getRect(find.byKey(const ValueKey('swipe-action-수정')));
    expect(del.width, 56);
    expect(edit.width, 48);
    expect(edit.left, del.right);
    final badge = tester.getRect(
      find.byKey(const ValueKey('swipe-badge')).last,
    );
    expect(badge.left - edit.left, 12);
  });

  group('밀기', () {
    Future<void> pumpList(
      WidgetTester tester, {
      required List<int> taps,
      List<PSwipeAction>? actions,
      bool reduceMotion = false,
      TextDirection direction = TextDirection.ltr,
      List<String> selected = const [],
    }) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSwipeActionsProvider(
            child: Column(
              children: [
                for (var i = 0; i < 2; i++)
                  PSwipeActions(
                    actions:
                        actions ??
                        [
                          _action(
                            PSwipeActionKind.primary,
                            onSelect: () => picked.add('수정$i'),
                          ),
                          _action(
                            PSwipeActionKind.destructive,
                            onSelect: () => picked.add('삭제$i'),
                          ),
                        ],
                    rowLabel: '줄$i',
                    child: _Row('줄$i', onTap: () => taps.add(i)),
                  ),
              ],
            ),
          ),
          reduceMotion: reduceMotion,
          direction: direction,
        ),
      );
    }

    Future<TestGesture> drag(
      WidgetTester tester,
      int row,
      List<Offset> moves, {
      bool release = true,
    }) async {
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('swipe-row')).at(row)),
      );
      for (final m in moves) {
        await g.moveBy(m);
        await tester.pump();
      }
      if (release) {
        await g.up();
        await tester.pumpAndSettle();
      }
      return g;
    }

    testWidgets('데드존 8 안은 움직이지 않고, 넘으면 처음부터 손가락을 1:1 로 따라간다', (tester) async {
      await pumpList(tester, taps: []);
      final g = await drag(tester, 0, [const Offset(-5, 0)], release: false);
      expect(_offset(tester), 0);
      await g.moveBy(const Offset(-5, 0));
      await tester.pump();
      // 10 — 데드존을 넘는 순간 판정하고, 그때까지의 이동도 쓴다(웹과 같다)
      expect(_offset(tester), -10);
      await g.moveBy(const Offset(-30, 0));
      await tester.pump();
      expect(_offset(tester), -40);
      await g.up();
      await tester.pumpAndSettle();
      // 104 의 40% = 41.6 — 40 은 모자라 닫힌다
      expect(_offset(tester), 0);
    });

    testWidgets('40% 이상 밀고 놓으면 열린 채 자리를 잡는다 — 끝까지 밀어도 트레이 폭에서 멈추고 실행하지 않는다', (
      tester,
    ) async {
      final taps = <int>[];
      await pumpList(tester, taps: taps);
      await drag(tester, 0, [const Offset(-50, 0)]);
      expect(_offset(tester), -104);
      expect(taps, isEmpty, reason: '밀고 난 직후의 탭은 줄로 가지 않는다');
      // 끝까지 — 줄이 너비만큼 밀려도 트레이 폭에서 멈춘다
      await pumpList(tester, taps: taps);
      final g = await drag(tester, 0, [const Offset(-330, 0)], release: false);
      expect(_offset(tester), -104);
      await g.up();
      await tester.pumpAndSettle();
      expect(_offset(tester), -104);
      expect(taps, isEmpty);
    });

    testWidgets('오른쪽으로 끌면 반응하지 않는다', (tester) async {
      await pumpList(tester, taps: []);
      final g = await drag(tester, 0, [const Offset(60, 0)], release: false);
      expect(_offset(tester), 0);
      await g.up();
      await tester.pumpAndSettle();
      expect(_offset(tester), 0);
    });

    testWidgets('세로로 확정되면 손을 뗄 때까지 가로로 되돌리지 않는다', (tester) async {
      await pumpList(tester, taps: []);
      final g = await drag(tester, 0, [const Offset(-4, 12)], release: false);
      await g.moveBy(const Offset(-120, 0));
      await tester.pump();
      expect(_offset(tester), 0);
      await g.up();
      await tester.pumpAndSettle();
      expect(_offset(tester), 0);
    });

    testWidgets('열린 줄은 25% 미만만 되돌리면 열린 채, 넘으면 닫힌다', (tester) async {
      await pumpList(tester, taps: []);
      await drag(tester, 0, [const Offset(-60, 0)]);
      expect(_offset(tester), -104);
      // 20(<26) 되돌림 — 열린 채
      await drag(tester, 0, [const Offset(20, 0)]);
      expect(_offset(tester), -104);
      // 40(≥26) 되돌림 — 닫힘
      await drag(tester, 0, [const Offset(40, 0)]);
      expect(_offset(tester), 0);
    });

    testWidgets('한 번에 한 줄 — 다른 줄을 끌기 시작하면 열려 있던 줄이 닫힌다', (tester) async {
      await pumpList(tester, taps: []);
      await drag(tester, 0, [const Offset(-60, 0)]);
      expect(_offset(tester, 0), -104);
      await drag(tester, 1, [const Offset(-60, 0)]);
      expect(_offset(tester, 0), 0);
      expect(_offset(tester, 1), -104);
    });

    testWidgets('열린 줄을 누르면 닫기만 한다 — 줄은 눌리지 않는다', (tester) async {
      final taps = <int>[];
      await pumpList(tester, taps: taps);
      await drag(tester, 0, [const Offset(-60, 0)]);
      await tester.tapAt(const Offset(40, 32));
      await tester.pumpAndSettle();
      expect(_offset(tester), 0);
      expect(taps, isEmpty);
      // 닫힌 뒤의 다음 누름은 줄로 간다(다음 pointerdown 에서 풀린다)
      await tester.tapAt(const Offset(40, 32));
      await tester.pump();
      expect(taps, [0]);
    });

    testWidgets('동작을 누르면 트레이를 먼저 닫고 실행한다 — 뒤집어 그려 삭제가 가장 안쪽이다', (tester) async {
      final taps = <int>[];
      final picked = <String>[];
      await pumpList(
        tester,
        taps: taps,
        actions: [
          _action(PSwipeActionKind.primary, onSelect: () => picked.add('수정')),
          _action(
            PSwipeActionKind.destructive,
            onSelect: () => picked.add('삭제'),
          ),
        ],
      );
      await drag(tester, 0, [const Offset(-60, 0)]);
      final del = tester.getRect(
        find.byKey(const ValueKey('swipe-action-삭제')).first,
      );
      final edit = tester.getRect(
        find.byKey(const ValueKey('swipe-action-수정')).first,
      );
      expect(del.left, lessThan(edit.left), reason: '삭제가 가장 안쪽(왼쪽)');
      expect(edit.right, 360, reason: '마지막 칸은 화면 끝');
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('swipe-action-삭제')).first),
      );
      await tester.pumpAndSettle();
      expect(picked, ['삭제']);
      expect(_offset(tester), 0);
    });

    testWidgets('막힌 동작은 눌러도 실행하지 않는다', (tester) async {
      final picked = <String>[];
      await pumpList(
        tester,
        taps: [],
        actions: [
          _action(
            PSwipeActionKind.neutral,
            label: '보관',
            disabled: true,
            onSelect: () => picked.add('보관'),
          ),
        ],
      );
      await drag(tester, 0, [const Offset(-40, 0)]);
      expect(_offset(tester), -56);
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('swipe-action-보관')).first),
      );
      await tester.pumpAndSettle();
      expect(picked, isEmpty);
    });

    testWidgets('Esc 로 열린 트레이를 닫는다 — 초점이 트레이 칸에 있을 때', (tester) async {
      await pumpList(tester, taps: []);
      await drag(tester, 0, [const Offset(-60, 0)]);
      expect(_offset(tester), -104);
      // 닫힌 줄의 숨긴 칸에는 초점이 가지 않는다 — 열린 뒤 Tab 이 첫 칸에 닿는다
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_offset(tester), 0);
    });

    testWidgets('모션 줄이기면 자리 잡기가 바로다 — 아니면 150ms 에 걸쳐 간다', (tester) async {
      await pumpList(tester, taps: [], reduceMotion: true);
      final g = await drag(tester, 0, [const Offset(-60, 0)], release: false);
      await g.up();
      await tester.pump();
      expect(_offset(tester), -104);

      await pumpList(tester, taps: []);
      final g2 = await drag(tester, 1, [const Offset(-60, 0)], release: false);
      await g2.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      // 그려진 자리 — 목표(transform)가 아니라 지금 자리
      final mid = -tester.getTopLeft(findText('줄1')).dx;
      expect(mid, greaterThan(60));
      expect(mid, lessThan(104));
      await tester.pumpAndSettle();
      expect(_offset(tester, 1), -104);
    });

    testWidgets('RTL — 오른쪽으로 밀고, 트레이는 왼쪽에서 나온다', (tester) async {
      await pumpList(tester, taps: [], direction: TextDirection.rtl);
      await drag(tester, 0, [const Offset(60, 0)]);
      expect(_offset(tester), 104);
      final edit = tester.getRect(
        find.byKey(const ValueKey('swipe-action-수정')).first,
      );
      expect(edit.left, lessThan(10), reason: '트레이는 왼쪽 끝');
    });

    testWidgets('닫힌 트레이는 의미 트리에서 빠지고, 열리면 "라벨: 줄 제목" 으로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpList(tester, taps: []);
      expect(find.bySemanticsLabel('삭제: 줄0'), findsNothing);
      expect(find.bySemanticsLabel('수정: 줄0'), findsNothing);
      await drag(tester, 0, [const Offset(-60, 0)]);
      expect(find.bySemanticsLabel('삭제: 줄0'), findsOneWidget);
      expect(find.bySemanticsLabel('수정: 줄0'), findsOneWidget);
      expect(find.bySemanticsLabel('삭제: 줄1'), findsNothing);
      handle.dispose();
    });

    testWidgets('enabled=false · actions=[] 는 줄만 그린다 — 서로 다른 뜻이다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Column(
            children: [
              PSwipeActions(
                actions: [_action(PSwipeActionKind.destructive)],
                enabled: false,
                child: const SizedBox(height: 64, child: Text('끔')),
              ),
              const PSwipeActions(
                actions: [],
                child: SizedBox(height: 64, child: Text('성립 안 함')),
              ),
            ],
          ),
        ),
      );
      expect(find.byKey(const ValueKey('swipe-actions')), findsNothing);
      expect(findText('끔'), findsOneWidget);
      expect(findText('성립 안 함'), findsOneWidget);
    });
  });

  testWidgets('스크롤하면 열린 줄이 닫힌다', (tester) async {
    tester.view.physicalSize = const Size(390, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        Brightness.light,
        SizedBox(
          height: 400,
          child: PSwipeActionsProvider(
            child: ListView(
              children: [
                for (var i = 0; i < 12; i++)
                  PSwipeActions(
                    actions: [_action(PSwipeActionKind.destructive)],
                    rowLabel: '줄$i',
                    child: _Row('줄$i', onTap: () {}),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final g = await tester.startGesture(const Offset(100, 32));
    await g.moveBy(const Offset(-50, 0));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(_offset(tester, 0), -56);
    // 세로로 훑는다 — 스크롤이 이긴다
    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pumpAndSettle();
    final first = tester.widgetList<AnimatedContainer>(
      find.byKey(const ValueKey('swipe-row')),
    );
    expect(
      first.every((w) => (w.transform?.getTranslation().x ?? 0) == 0),
      isTrue,
      reason: '열린 줄이 없다',
    );
  });

  group('줄 끝 ⋮', () {
    testWidgets('이름 "{줄 제목} 더보기" — 같은 동작 · 같은 차례로 시트가 열리고, 줄을 고르면 실행한다', (
      tester,
    ) async {
      final picked = <String>[];
      final actions = [
        _action(PSwipeActionKind.neutral, onSelect: () => picked.add('고정')),
        _action(PSwipeActionKind.primary, onSelect: () => picked.add('수정')),
        _action(PSwipeActionKind.destructive, onSelect: () => picked.add('삭제')),
      ];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PSwipeActionsMore(actions: actions, rowLabel: '스타벅스'),
        ),
      );
      expect(find.bySemanticsLabel('스타벅스 더보기'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('스타벅스 더보기'));
      await tester.pumpAndSettle();
      final names = ['고정', '수정', '삭제'];
      final tops = [
        for (final n in names)
          tester
              .getTopLeft(
                find
                    .byWidgetPredicate(
                      (w) => w is Text && w.semanticsLabel == n,
                    )
                    .first,
              )
              .dy,
      ];
      expect(tops[0], lessThan(tops[1]));
      expect(tops[1], lessThan(tops[2]));
      await tester.tap(
        find
            .byWidgetPredicate((w) => w is Text && w.semanticsLabel == '삭제')
            .first,
      );
      await tester.pumpAndSettle();
      expect(picked, ['삭제']);
      handle.dispose();
    });

    testWidgets('⋮ 아이콘 18 · 누르는 영역 44', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Align(
            alignment: Alignment.topLeft,
            child: PSwipeActionsMore(
              actions: [_action(PSwipeActionKind.destructive)],
              rowLabel: '스타벅스',
            ),
          ),
        ),
      );
      final icon = tester.widget<Icon>(
        find.byIcon(LucideIcons.ellipsisVertical),
      );
      expect(icon.size, 18);
      final hit = tester.getRect(find.byType(PSwipeActionsMore));
      expect(hit.width, greaterThanOrEqualTo(40));
    });
  });
}
