// 옛 부품(lib/shared/widgets)의 공용 접근성 — 01A-062 · 071 · 082 · 090 · 091.
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_checkbox.dart';
import 'package:groo_damda_app/shared/widgets/p_chip.dart';
import 'package:groo_damda_app/shared/widgets/p_progress.dart';
import 'package:groo_damda_app/shared/widgets/p_accordion.dart';
import 'package:groo_damda_app/shared/widgets/p_radio_list.dart';
import 'package:groo_damda_app/shared/widgets/p_segmented.dart';
import 'package:groo_damda_app/shared/widgets/p_tabs.dart';
import 'package:groo_damda_app/shared/widgets/p_type_chip.dart';
import 'package:groo_damda_app/shared/widgets/p_tile.dart';
import '../support/plain_text.dart';

Widget _host(Widget child, {Brightness mode = Brightness.light}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

Iterable<SemanticsData> _nodes(WidgetTester tester) {
  final out = <SemanticsData>[];
  void walk(SemanticsNode n) {
    out.add(n.getSemanticsData());
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return out;
}

void main() {
  testWidgets('동작 줄이기를 켜면 로딩 원이 돌지 않는다', (tester) async {
    for (final reduce in [true, false]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: _host(const PCircularProgressIndicator()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, !reduce, reason: 'reduce=$reduce');
    }
  });

  for (final mode in Brightness.values) {
    testWidgets('PButton ${mode.name} — 막힘은 전용 색(불투명도 없음), 버튼 역할, 누르는 영역 44', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PButton(label: '저장', onPressed: null),
              PButton(label: '삭제', onPressed: () {}, size: PButtonSize.sm),
            ],
          ),
          mode: mode,
        ),
      );
      final t = mode == Brightness.dark ? GrooTokens.dark : GrooTokens.light;
      expect(find.byType(Opacity), findsNothing, reason: '불투명도로 흐리게 하지 않는다');
      final disabledText = tester.widget<Text>(findText('저장'));
      expect(disabledText.style!.color, t.fgDisabled);
      final saveNode = _nodes(tester).firstWhere((n) => n.label.contains('저장'));
      expect(saveNode.flagsCollection.isButton, isTrue);
      // 보이는 sm 은 32 — 위 6 에서도 눌린다(44)
      var taps = 0;
      await tester.pumpWidget(
        _host(
          PButton(label: '삭제', onPressed: () => taps++, size: PButtonSize.sm),
          mode: mode,
        ),
      );
      final r = tester.getRect(find.byType(PButton));
      await tester.tapAt(Offset(r.center.dx, r.top - 5));
      expect(taps, 1);
      handle.dispose();
    });
  }

  testWidgets('PChip · PTabs · PCheckbox — 고른 상태를 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PChip(label: '식비', selected: true, onTap: () {}),
            PTabs<int>(
              value: 1,
              onChanged: (_) {},
              items: const [
                PTabItem(value: 1, label: '지출'),
                PTabItem(value: 2, label: '수입'),
              ],
            ),
            PCheckbox(value: true, onChanged: (_) {}, label: '동의'),
          ],
        ),
      ),
    );
    final nodes = _nodes(tester).toList();
    bool has(String label, bool Function(SemanticsData) test) =>
        nodes.any((n) => n.label.contains(label) && test(n));
    expect(
      has('식비', (n) => n.flagsCollection.isSelected == Tristate.isTrue),
      isTrue,
    );
    expect(
      has('지출', (n) => n.flagsCollection.isSelected == Tristate.isTrue),
      isTrue,
    );
    expect(
      has('수입', (n) => n.flagsCollection.isSelected == Tristate.isFalse),
      isTrue,
    );
    expect(
      has('동의', (n) => n.flagsCollection.isChecked == CheckedState.isTrue),
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('PTile · PAccordion 막힘은 불투명도 대신 전용 글자색', (tester) async {
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PTile(
              swatch: SizedBox(),
              label: '라이트',
              selected: false,
              onTap: null,
            ),
            PAccordion(
              items: const [
                PAccordionItem(
                  value: 'a',
                  title: '막힌 항목',
                  content: Text('내용'),
                  disabled: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final t = GrooTokens.light;
    expect(find.byType(Opacity), findsNothing);
    expect(tester.widget<Text>(findText('라이트')).style!.color, t.fgDisabled);
    expect(tester.widget<Text>(findText('막힌 항목')).style!.color, t.fgDisabled);
  });

  for (final reduce in [false, true]) {
    testWidgets(
      '누름 축소(01A-063) — 옛 PButton · PChip 은 누르는 동안 줄고, 동작 줄이기면 줄지 않는다 ($reduce)',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: _host(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PButton(label: '저장', onPressed: () {}),
                  PChip(label: '식비', selected: false, onTap: () {}),
                ],
              ),
            ),
          ),
        );
        double scaleOf(Finder f) => tester
            .widget<AnimatedScale>(
              find.ancestor(of: f, matching: find.byType(AnimatedScale)).first,
            )
            .scale;
        for (final label in ['저장', '식비']) {
          final f = findText(label);
          expect(scaleOf(f), 1);
          final g = await tester.startGesture(tester.getCenter(f));
          await tester.pump();
          if (reduce) {
            expect(scaleOf(f), 1);
          } else {
            expect(scaleOf(f), lessThan(1));
            expect(scaleOf(f), greaterThan(0.9));
          }
          await g.up();
          await tester.pump();
          expect(scaleOf(f), 1);
        }
      },
    );
  }

  testWidgets('옛 PSegmented · PRadioList · PTypeChip — 고른 상태를 읽고 44 로 눌린다', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var picked = '';
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PSegmented<int>(
              value: 1,
              onChanged: (_) {},
              options: const [
                PSegmentOption(value: 1, label: '지출'),
                PSegmentOption(value: 2, label: '수입'),
              ],
            ),
            PRadioList<int>(
              value: 1,
              onChanged: (_) {},
              items: const [
                PRadioListItem(value: 1, label: '하나'),
                PRadioListItem(value: 2, label: '둘'),
              ],
            ),
            PTypeChip(label: '반복', active: true, onTap: () => picked = 'chip'),
          ],
        ),
      ),
    );
    final nodes = _nodes(tester).toList();
    bool sel(String label, Tristate want) => nodes.any(
      (n) => n.label.contains(label) && n.flagsCollection.isSelected == want,
    );
    expect(sel('지출', Tristate.isTrue), isTrue);
    expect(sel('수입', Tristate.isFalse), isTrue);
    expect(sel('반복', Tristate.isTrue), isTrue);
    expect(
      nodes.any(
        (n) =>
            n.label.contains('하나') &&
            n.flagsCollection.isChecked == CheckedState.isTrue,
      ),
      isTrue,
    );
    // 칩(높이 약 40) 위 · 아래로도 눌린다 — 보이는 상자 위 2
    final chip = tester.getRect(find.byType(PTypeChip));
    await tester.tapAt(Offset(chip.center.dx, chip.top - 1));
    expect(picked, 'chip');
    handle.dispose();
  });

  testWidgets('PTabs — 탭 목록(tabBar) 안의 탭(tab), 고른 탭도 누를 수 있는 노드다(03G-013)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final picked = <int>[];
    await tester.pumpWidget(
      _host(
        PTabs<int>(
          value: 1,
          onChanged: picked.add,
          items: const [
            PTabItem(value: 1, label: '지출'),
            PTabItem(value: 2, label: '수입'),
            PTabItem(value: 3, label: '이체', disabled: true),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final nodes = _nodes(tester).toList();
    expect(nodes.where((n) => n.role == SemanticsRole.tabBar), hasLength(1));
    final tabs = nodes.where((n) => n.role == SemanticsRole.tab).toList();
    expect(tabs.map((n) => n.label), ['지출, 탭 1/3', '수입, 탭 2/3', '이체, 탭 3/3']);
    // 고른 탭(지출)에도 tap 동작이 있다 — 눌러도 아무 일 없다
    final selected = tabs.firstWhere((n) => n.label.startsWith('지출'));
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    expect(selected.hasAction(SemanticsAction.tap), isTrue);
    final other = tabs.firstWhere((n) => n.label.startsWith('수입'));
    expect(other.flagsCollection.isSelected, Tristate.isFalse);
    expect(other.hasAction(SemanticsAction.tap), isTrue);
    // 막힌 탭은 비활성
    final blocked = tabs.firstWhere((n) => n.label.startsWith('이체'));
    expect(blocked.flagsCollection.isEnabled, Tristate.isFalse);
    // 읽기 도구의 탭 동작이 값을 바꾼다
    tester.semantics.tap(find.semantics.byLabel('수입, 탭 2/3'));
    await tester.pump();
    expect(picked, [2]);
    tester.semantics.tap(find.semantics.byLabel('지출, 탭 1/3'));
    await tester.pump();
    expect(picked, [2], reason: '고른 탭을 눌러도 부르지 않는다');
    handle.dispose();
  });
}
