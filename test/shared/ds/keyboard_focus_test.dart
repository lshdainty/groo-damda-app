// 키보드 — 앱도 Tab 으로 닿고(버튼 · 토글 · 체크 · 라디오 · 스위치 · 슬라이더), Space · Enter 로 누르며, 키보드로 초점이
// 올 때만 링(두께 2 · 띄움 2 · stroke-focus-ring)을 그린다(03A-005 ~ 008, 사용자 결정 2026-10-08 E2).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/radio/p_radio.dart';
import 'package:groo_damda_app/shared/ds/slider/p_slider.dart';
import 'package:groo_damda_app/shared/ds/switch/p_switch.dart';
import 'package:groo_damda_app/shared/ds/toggle/p_toggle.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:flutter/semantics.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../support/plain_text.dart';

Widget _host(Brightness mode, Widget child) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(body: Center(child: child)),
);

final _ring = find.byKey(const ValueKey('focus-ring'));

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

Color _ringColor(WidgetTester tester) {
  final deco =
      tester.widget<DecoratedBox>(_ring.first).decoration as BoxDecoration;
  return (deco.border! as Border).top.color;
}

void main() {
  for (final mode in Brightness.values) {
    final dark = mode == Brightness.dark;
    group('${dark ? "다크" : "라이트"} 키보드 링', () {
      testWidgets('PButton — Tab 으로 닿고 링, Space · Enter 로 누른다', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _host(mode, PButton(label: '저장', onPressed: () => taps++)),
        );
        expect(_ring, findsNothing, reason: '처음엔 링 없음');
        await _tab(tester);
        expect(_ring, findsOneWidget);
        final c = (dark ? PColors.dark : PColors.light);
        expect(_ringColor(tester), c.strokeFocusRing);
        final box = tester.getRect(find.byType(PButton));
        final ring = tester.getRect(_ring);
        expect(box.left - ring.left, 4, reason: '띄움 2 + 두께 2');
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(taps, 2);
      });

      testWidgets('PButton — 막힌 버튼은 Tab 에 들지 않고, 손가락으로 눌러도 링이 없다', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(mode, const PButton(label: '저장', onPressed: null)),
        );
        await _tab(tester);
        expect(_ring, findsNothing);
        await tester.pumpWidget(
          _host(mode, PButton(label: '저장', onPressed: () {})),
        );
        await tester.tap(findText('저장'));
        await tester.pump();
        expect(_ring, findsNothing, reason: '터치 초점에는 링 없음');
      });

      testWidgets('PToggle — 링(모서리 8), inverted 는 흰색', (tester) async {
        for (final inverted in [false, true]) {
          await tester.pumpWidget(
            _host(
              mode,
              PToggle(
                semanticLabel: '관심',
                pressed: false,
                onChanged: (_) {},
                icon: LucideIcons.eye,
                pressedIcon: LucideIcons.eyeOff500,
                tone: inverted ? PToggleTone.inverted : PToggleTone.defaultTone,
              ),
            ),
          );
          await _tab(tester);
          expect(_ring, findsOneWidget);
          final c = (dark ? PColors.dark : PColors.light);
          expect(
            _ringColor(tester),
            inverted ? c.staticWhite : c.strokeFocusRing,
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pump();
        }
      });

      testWidgets('PCheckbox · PRadio · PSwitch — 표시 둘레에 링', (tester) async {
        await tester.pumpWidget(
          _host(
            mode,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PCheckbox(label: '동의', checked: false, onChanged: (_) {}),
                PRadioGroup<int>(
                  value: 1,
                  onChanged: (_) {},
                  children: const [PRadio<int>(value: 1, label: '하나')],
                ),
                PSwitch(label: '알림', checked: false, onChanged: (_) {}),
              ],
            ),
          ),
        );
        for (var i = 0; i < 3; i++) {
          await _tab(tester);
          expect(_ring, findsOneWidget, reason: '${i + 1}번째');
        }
      });
    });
  }

  testWidgets('PSlider — Tab 으로 닿으면 바로 링 + 이름 없는 초점 노드가 없다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Brightness.light,
        SizedBox(
          width: 300,
          child: PSlider(value: 40, onChanged: (_) {}, label: '음량'),
        ),
      ),
    );
    await _tab(tester);
    expect(find.byKey(const ValueKey('slider-ring-0')), findsOneWidget);
    // 슬라이더 안 노드 — 이름 · 값이 있는 슬라이더 하나뿐, 이름 없는 focusable 은 없다
    final nodes = <SemanticsData>[];
    void walk(SemanticsNode n) {
      nodes.add(n.getSemanticsData());
      n.visitChildren((c) {
        walk(c);
        return true;
      });
    }

    walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    final named = nodes.where((n) => n.label == '음량').toList();
    expect(named.length, 1);
    expect(named.single.flagsCollection.isSlider, isTrue);
    // 초점 동작(focus)을 가진 노드는 이름 있는 슬라이더 하나뿐 — 이름 없는 빈 노드가 없다
    final focusActions = nodes.where((n) => n.hasAction(SemanticsAction.focus));
    expect(focusActions.every((n) => n.label.isNotEmpty), isTrue);
    handle.dispose();
  });

  testWidgets('Field 안 묶음의 맨 위 줄은 위 6 에서도 눌린다(44)', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Brightness.light,
        SizedBox(
          width: 300,
          child: PField(
            label: '약관',
            child: PCheckboxGroup(
              children: [
                PCheckbox(
                  label: '동의',
                  checked: false,
                  onChanged: (_) => taps++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final row = tester.getRect(find.byType(PCheckbox));
    // 줄 높이가 44 보다 낮으면 위 (44 − 높이) ÷ 2 까지 눌린다
    final reach = (44 - row.height) / 2;
    expect(reach, greaterThan(0));
    await tester.tapAt(Offset(row.left + 4, row.top - reach + 0.5));
    expect(taps, 1, reason: '줄 위 ${reach}px 안');
  });

  testWidgets('Field 밖 단독 체크 · 라디오 묶음의 첫 · 끝 줄도 위 · 아래 6 까지 눌린다(44)', (
    tester,
  ) async {
    var checks = 0;
    var radios = 0;
    await tester.pumpWidget(
      _host(
        Brightness.light,
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            PCheckboxGroup(
              children: [
                PCheckbox(
                  label: '동의',
                  checked: false,
                  onChanged: (_) => checks++,
                ),
              ],
            ),
            const SizedBox(height: 40),
            PRadioGroup<int>(
              value: 1,
              onChanged: (_) => radios++,
              children: const [PRadio<int>(value: 2, label: '둘')],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
    final c = tester.getRect(find.byType(PCheckbox));
    final reach = (44 - c.height) / 2;
    await tester.tapAt(Offset(c.left + 4, c.top - reach + 0.5));
    await tester.tapAt(Offset(c.left + 4, c.bottom + reach - 0.5));
    expect(checks, 2, reason: '체크 묶음 첫 · 끝 줄 밖 ${reach}px');
    final r = tester.getRect(find.byType(PRadio<int>));
    final reachR = (44 - r.height) / 2;
    await tester.tapAt(Offset(r.left + 4, r.top - reachR + 0.5));
    await tester.tapAt(Offset(r.left + 4, r.bottom + reachR - 0.5));
    expect(radios, 2, reason: '라디오 묶음 첫 · 끝 줄 밖 ${reachR}px');
  });
}
