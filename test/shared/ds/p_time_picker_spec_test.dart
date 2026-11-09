// Time Picker 가 스펙 값(test/fixtures/design_spec/time-picker.json)대로인지 — 분 간격 × 상태(기본 · 막힘) × 라이트 · 다크의
// 휠 높이 220 · 칼럼 순서(오전·오후 → 시 → 분) · 칼럼 정렬 · 항목(오전·오후 두 칸, 시 1 ~ 12, 분 간격대로 두 자리), 그리고
// 값 규칙(시 11 ↔ 12 에서 오전 · 오후가 따라 바뀜 · 분 55 → 00 은 시 그대로 · 오전 · 오후 바꾸기 · 반올림 · 빈 값 · 정오 · 자정
// 경계)과 읽는 말. 휠의 크기 · 색 · 띠 · 안개는 wheel-picker.yaml 이 정하고 p_wheel_picker_spec_test.dart 가 잰다.
//
// 앱에 없는 것 — 열 때 시 칼럼에 초점을 두는 것(웹 autoFocus: 칼럼의 초점 자리를 부모가 쥐지 못한다). 키보드는 칼럼마다
// Tab 자리 하나 · ↑ ↓ · Home · End 를 휠 부품이 맡는다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/ds/time_picker/time_picker_demo.dart';
import 'package:groo_damda_app/shared/ds/wheel_picker/p_wheel_picker.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('time-picker');

Widget _host(Brightness mode, Widget child) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 280, child: child),
    ),
  ),
);

Finder _col(String name) => find.byWidgetPredicate(
  (w) => w is PWheelPickerColumn && w.semanticLabel == name,
  description: '칼럼 $name',
);
Finder _layerA(String name) =>
    find.descendant(of: _col(name), matching: find.byType(ListWheelScrollView));

/// 띠(가운데 줄)에 놓인 항목의 글.
String? _centerLabel(WidgetTester tester, String name) {
  final y = tester.getRect(find.byKey(const ValueKey('wheel-root'))).center.dy;
  for (final e
      in find
          .descendant(of: _layerA(name), matching: find.byType(Text))
          .evaluate()) {
    final box = e.renderObject! as RenderBox;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    if ((center.dy - y).abs() < 1) return (e.widget as Text).data;
  }
  return null;
}

/// 칼럼 목록 — 칼럼은 오전·오후 → 시 → 분 순이다.
List<PWheelPickerColumn<dynamic>> _columns(WidgetTester tester) => tester
    .widgetList(find.byWidgetPredicate((w) => w is PWheelPickerColumn))
    .cast<PWheelPickerColumn<dynamic>>()
    .toList();

Future<void> _tab(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// 값을 쥔 쪽 — 휠이 멈춘 뒤 정해진 값을 받아 다시 넘긴다.
class _Holder extends StatefulWidget {
  const _Holder({
    required this.initial,
    required this.calls,
    this.minuteStep = 5,
  });

  final PTimeValue? initial;
  final List<PTimeValue> calls;
  final int minuteStep;

  @override
  State<_Holder> createState() => _HolderState();
}

class _HolderState extends State<_Holder> {
  late PTimeValue? _value = widget.initial;

  @override
  Widget build(BuildContext context) => PTimePicker(
    value: _value,
    minuteStep: widget.minuteStep,
    now: DateTime(2026, 10, 15, 9, 13),
    onChanged: (v) {
      widget.calls.add(v);
      setState(() => _value = v);
    },
  );
}

void main() {
  group('스펙 값', () {
    final combos = _spec.combos(['minuteStep']);
    for (final mode in Brightness.values) {
      for (final combo in combos) {
        for (final state in _spec.states) {
          final step = int.parse(combo['minuteStep']!);
          final title =
              '${mode.name} · 분 간격 $step · $state — 휠 220 · 칼럼 순서 · 정렬 · 항목';
          testWidgets(title, (tester) async {
            final want = _spec.resolve(combo, state);
            await tester.pumpWidget(
              _host(
                mode,
                PTimePicker(
                  value: const PTimeValue(15, 30),
                  minuteStep: step,
                  disabled: state == 'disabled',
                ),
              ),
            );
            await tester.pumpAndSettle();

            // root.height — 44 × 5
            expect(
              tester.getSize(find.byKey(const ValueKey('wheel-root'))).height,
              want['root.height'],
            );
            // root.columnOrder — 오전·오후 → 시 → 분
            final cols = _columns(tester);
            expect(cols.map((c) => c.semanticLabel), ['오전/오후', '시', '분']);
            expect(want['root.columnOrder'], '오전·오후 → 시 → 분');

            final period = cols[0];
            final hour = cols[1];
            final minute = cols[2];
            // 정렬 — 오전·오후 center · 시 right · 분 center
            expect(period.align.name, want['periodColumn.align']);
            expect(hour.align.name, want['hourColumn.align']);
            expect(minute.align.name, want['minuteColumn.align']);
            // 항목 — 오전·오후 두 칸(반복 없음) · 시 1 ~ 12(반복) · 분 간격대로(반복)
            expect(period.options.map((o) => o.label), ['오전', '오후']);
            expect(period.loop, isFalse);
            expect(hour.options.map((o) => o.label), [
              for (var i = 1; i <= 12; i++) '$i',
            ]);
            expect(hour.loop, isTrue);
            expect(minute.options, hasLength(60 ~/ step));
            expect(minute.options.first.label, '00');
            expect(minute.options.map((o) => o.value), [
              for (var i = 0; i < 60 ~/ step; i++) i * step,
            ]);
            expect(
              minute.options.every((o) => o.label.length == 2),
              isTrue,
              reason: '분은 두 자리',
            );
            expect(minute.loop, isTrue);

            // 값 — 오후 3 30
            expect(_centerLabel(tester, '오전/오후'), '오후');
            expect(_centerLabel(tester, '시'), '3');
            expect(
              _centerLabel(tester, '분'),
              (30 - 30 % step).toString().padLeft(2, '0'),
            );
            // 막힘 — 휠이 막힌다(값은 그대로)
            final disabled = state == 'disabled';
            expect(
              tester.widget<PWheelPicker>(find.byType(PWheelPicker)).disabled,
              disabled,
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }

    test('단위 글자(시 · 분)는 항목에 쓰지 않는다 — 값이 숫자만', () {
      expect(formatTimeValue(const PTimeValue(15, 0)), '오후 3:00');
    });

    test('분 간격 한 벌 — 1 · 5 · 10 · 15 · 30 이고 기본은 1(스펙 minuteStep 기본을 읽는다)', () {
      expect(pMinuteSteps, _spec.axes['minuteStep']!.map(int.parse));
      expect(_spec.defaults['minuteStep'], '1');
      expect(
        const PTimePicker().minuteStep,
        int.parse(_spec.defaults['minuteStep']!),
      );
    });
  });

  group('roundTimeToStep · formatTimeValue', () {
    test('분 간격으로 시각 전체를 반올림한다 — 9:58 → 10:00, 23:58 → 0:00 으로 돈다', () {
      expect(
        roundTimeToStep(const PTimeValue(9, 13), 5),
        const PTimeValue(9, 15),
      );
      expect(
        roundTimeToStep(const PTimeValue(9, 58), 5),
        const PTimeValue(10, 0),
      );
      expect(
        roundTimeToStep(const PTimeValue(23, 58), 5),
        const PTimeValue(0, 0),
      );
      expect(
        roundTimeToStep(const PTimeValue(23, 50), 30),
        const PTimeValue(0, 0),
      );
      expect(
        roundTimeToStep(const PTimeValue(9, 7), 15),
        const PTimeValue(9, 0),
      );
      // 이미 맞는 값 · 간격 1 은 그대로
      expect(
        roundTimeToStep(const PTimeValue(9, 15), 5),
        const PTimeValue(9, 15),
      );
      expect(
        roundTimeToStep(const PTimeValue(23, 59), 1),
        const PTimeValue(23, 59),
      );
    });

    test('DateTime 은 다음 날로 넘어가고 초는 버린다', () {
      expect(
        roundDateTimeToStep(DateTime(2026, 12, 31, 23, 58, 40), 5),
        DateTime(2027, 1, 1, 0, 0),
      );
      expect(
        roundDateTimeToStep(DateTime(2026, 10, 15, 9, 13, 40), 5),
        DateTime(2026, 10, 15, 9, 15),
      );
      // 윤일 — 2028-02-29 23:58 → 3월 1일 0시
      expect(
        roundDateTimeToStep(DateTime(2028, 2, 29, 23, 58), 5),
        DateTime(2028, 3, 1),
      );
    });

    test(
      '칸 표기는 오전 · 오후 12시간, 0 을 채우지 않는 시 + 두 자리 분 — 자정은 오전 12, 정오는 오후 12',
      () {
        expect(formatTimeValue(const PTimeValue(0, 0)), '오전 12:00');
        expect(formatTimeValue(const PTimeValue(0, 5)), '오전 12:05');
        expect(formatTimeValue(const PTimeValue(9, 5)), '오전 9:05');
        expect(formatTimeValue(const PTimeValue(11, 59)), '오전 11:59');
        expect(formatTimeValue(const PTimeValue(12, 0)), '오후 12:00');
        expect(formatTimeValue(const PTimeValue(15, 30)), '오후 3:30');
        expect(formatTimeValue(const PTimeValue(23, 55)), '오후 11:55');
        expect(formatTimeValue(null), '');
      },
    );
  });

  group('값 규칙', () {
    testWidgets('값이 없으면 지금을 분 간격에 맞춰 반올림한 자리를 짚기만 한다 — onChanged 를 부르지 않는다', (
      tester,
    ) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTimePicker(
            now: DateTime(2026, 10, 15, 9, 13),
            minuteStep: 5,
            onChanged: calls.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_centerLabel(tester, '오전/오후'), '오전');
      expect(_centerLabel(tester, '시'), '9');
      expect(_centerLabel(tester, '분'), '15');
      expect(calls, isEmpty);
    });

    testWidgets(
      '간격에 안 맞는 값은 가장 가까운 칸으로 반올림해 보이되 그것만으로 알리지 않는다 — 23:58 은 오전 12:00',
      (tester) async {
        final calls = <PTimeValue>[];
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PTimePicker(
              value: const PTimeValue(23, 58),
              minuteStep: 5,
              onChanged: calls.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_centerLabel(tester, '오전/오후'), '오전');
        expect(_centerLabel(tester, '시'), '12');
        expect(_centerLabel(tester, '분'), '00');
        expect(calls, isEmpty);
      },
    );

    testWidgets('분 휠이 55 → 00 을 넘어도 시는 그대로다(10시 55분 → 10시 00분)', (
      tester,
    ) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Holder(initial: const PTimeValue(10, 55), calls: calls),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 3); // 분
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(calls, [const PTimeValue(10, 0)]);
      expect(_centerLabel(tester, '시'), '10');
      expect(_centerLabel(tester, '분'), '00');
    });

    testWidgets('분 휠이 00 → 55 로 거꾸로 넘어도 시는 그대로다', (tester) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Holder(initial: const PTimeValue(10, 0), calls: calls),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 3);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(calls, [const PTimeValue(10, 55)]);
      expect(_centerLabel(tester, '시'), '10');
    });

    testWidgets('시 휠이 11 → 12 를 넘으면 오전 · 오후가 따라 바뀐다(오전 11 → 오후 12)', (
      tester,
    ) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Holder(initial: const PTimeValue(11, 30), calls: calls),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 2); // 시
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(calls, [const PTimeValue(12, 30)]);
      expect(_centerLabel(tester, '시'), '12');
      expect(_centerLabel(tester, '오전/오후'), '오후');
    });

    testWidgets('오후 11 → 오전 12(자정)로, 거꾸로 오전 12 → 오후 11 로 — 하루를 넘어 돈다', (
      tester,
    ) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Holder(initial: const PTimeValue(23, 0), calls: calls),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 2);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(calls.last, const PTimeValue(0, 0));
      expect(_centerLabel(tester, '오전/오후'), '오전');
      expect(_centerLabel(tester, '시'), '12');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(calls.last, const PTimeValue(23, 0));
      expect(_centerLabel(tester, '오전/오후'), '오후');
      expect(_centerLabel(tester, '시'), '11');
    });

    testWidgets('오후 12 에서 거꾸로 11 로 가면 오전 11 — 정오 경계', (tester) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Holder(initial: const PTimeValue(12, 0), calls: calls),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 2);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(calls.last, const PTimeValue(11, 0));
      expect(_centerLabel(tester, '오전/오후'), '오전');
    });

    testWidgets('시를 11 → 10 처럼 오전 · 오후가 안 걸리는 칸으로 옮기면 그대로 오전', (tester) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Holder(initial: const PTimeValue(11, 0), calls: calls),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 2);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(calls.last, const PTimeValue(10, 0));
      expect(_centerLabel(tester, '오전/오후'), '오전');
    });

    testWidgets('오전 · 오후를 바꾸면 시 · 분은 그대로 12시간을 더하거나 뺀다', (tester) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Holder(initial: const PTimeValue(9, 30), calls: calls),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 1); // 오전·오후
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(calls.last, const PTimeValue(21, 30));
      expect(_centerLabel(tester, '시'), '9');
      expect(_centerLabel(tester, '분'), '30');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(calls.last, const PTimeValue(9, 30));
    });

    testWidgets('자정(오전 12)에서 오후로 바꾸면 정오(오후 12) — 12시간을 더한다', (tester) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Holder(initial: const PTimeValue(0, 0), calls: calls),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 1);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(calls.last, const PTimeValue(12, 0));
      expect(_centerLabel(tester, '시'), '12');
    });

    testWidgets('오전 · 오후는 두 칸에서 멈춘다 — 오전에서 ↑ 는 그대로', (tester) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Holder(initial: const PTimeValue(9, 0), calls: calls),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 1);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(calls, isEmpty);
      expect(_centerLabel(tester, '오전/오후'), '오전');
    });

    testWidgets('굴리는 동안은 알리지 않고 멈춘 뒤 한 번만 — 값을 안 줘도(제어하지 않아도) 휠이 따라간다', (
      tester,
    ) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTimePicker(
            now: DateTime(2026, 10, 15, 9, 0),
            minuteStep: 5,
            onChanged: calls.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 3);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 50));
      expect(calls, isEmpty);
      await tester.pumpAndSettle();
      expect(calls, [const PTimeValue(9, 5)]);
      expect(_centerLabel(tester, '분'), '05');
    });

    testWidgets('Home · End — 시는 1 · 12(첫 · 끝 항목)', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, PTimePicker(value: const PTimeValue(15, 30))),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 2);
      await _key(tester, LogicalKeyboardKey.end);
      expect(_centerLabel(tester, '시'), '12');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_centerLabel(tester, '시'), '1');
    });

    testWidgets(
      'Home · End 는 오전 · 오후를 그대로 두고 1 · 12 로 간다 — 지나간 칸을 세지 않는다(03-C 3A)',
      (tester) async {
        final calls = <PTimeValue>[];
        await tester.pumpWidget(
          _host(
            Brightness.light,
            _Holder(initial: const PTimeValue(15, 30), calls: calls),
          ),
        );
        await tester.pumpAndSettle();
        await _tab(tester, 2);
        await _key(tester, LogicalKeyboardKey.end);
        expect(calls.last, const PTimeValue(12, 30)); // 오후 12
        expect(_centerLabel(tester, '오전/오후'), '오후');
        await _key(tester, LogicalKeyboardKey.home);
        expect(calls.last, const PTimeValue(13, 30)); // 오후 1
        expect(_centerLabel(tester, '오전/오후'), '오후');
        expect(_centerLabel(tester, '시'), '1');
      },
    );

    testWidgets('오전 9 에서 End → 오전 12(0시), Home → 오전 1', (tester) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Holder(initial: const PTimeValue(9, 30), calls: calls),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 2);
      await _key(tester, LogicalKeyboardKey.end);
      expect(calls.last, const PTimeValue(0, 30));
      expect(_centerLabel(tester, '오전/오후'), '오전');
      await _key(tester, LogicalKeyboardKey.home);
      expect(calls.last, const PTimeValue(1, 30));
    });

    testWidgets('분 간격 30 — 두 칸(00 · 30), 한 칸 내리면 30', (tester) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Holder(
            initial: const PTimeValue(9, 0),
            calls: calls,
            minuteStep: 30,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 3);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(calls.last, const PTimeValue(9, 30));
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(calls.last, const PTimeValue(9, 0));
    });

    testWidgets('알 수 없는 분 간격은 1 로 본다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PTimePicker(value: PTimeValue(9, 0), minuteStep: 7),
        ),
      );
      await tester.pumpAndSettle();
      expect(_columns(tester)[2].options, hasLength(60));
    });
  });

  group('읽는 말', () {
    testWidgets(
      '휠은 이름 있는 묶음, 칼럼은 조절 가능한 값 — 읽는 값은 단위 글자 없이 "오후" · "3" · "00"',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            Brightness.light,
            const PTimePicker(
              value: PTimeValue(15, 0),
              minuteStep: 5,
              semanticLabel: '시작 시각',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('시작 시각'), findsOneWidget);
        expect(
          tester.getSemantics(find.bySemanticsLabel('오전/오후')),
          isSemantics(
            label: '오전/오후',
            value: '오후',
            decreasedValue: '오전',
            hasEnabledState: true,
            isEnabled: true,
            hasDecreaseAction: true,
            isFocusable: true,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('시')),
          isSemantics(
            label: '시',
            value: '3',
            increasedValue: '4',
            decreasedValue: '2',
            hasEnabledState: true,
            isEnabled: true,
            hasIncreaseAction: true,
            hasDecreaseAction: true,
            isFocusable: true,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('분')),
          isSemantics(
            label: '분',
            value: '00',
            increasedValue: '05',
            decreasedValue: '55',
            hasEnabledState: true,
            isEnabled: true,
            hasIncreaseAction: true,
            hasDecreaseAction: true,
            isFocusable: true,
          ),
        );
        semantics.dispose();
      },
    );

    testWidgets('이름은 아무것도 없으면 "시간 선택" · 글 한 벌을 바꿀 수 있다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, const PTimePicker(value: PTimeValue(9, 0))),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('시간 선택'), findsOneWidget);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PTimePicker(
            value: PTimeValue(15, 0),
            labels: PTimePickerLabels(
              root: 'Time',
              period: 'AM/PM',
              hour: 'Hour',
              minute: 'Minute',
              am: 'AM',
              pm: 'PM',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Time'), findsOneWidget);
      expect(find.bySemanticsLabel('Hour'), findsOneWidget);
      expect(_centerLabel(tester, 'AM/PM'), 'PM');
      semantics.dispose();
    });

    testWidgets('막힌 휠 — 값은 그대로 읽히고 굴릴 수 없다', (tester) async {
      final calls = <PTimeValue>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PTimePicker(
            value: const PTimeValue(9, 30),
            disabled: true,
            onChanged: calls.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tab(tester, 3);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(_centerLabel(tester, '분'), '30');
    });
  });

  group('시트 — 고르는 동안 칸은 그대로, "완료" 로 넣는다', () {
    Widget opener(Future<void> Function(BuildContext) open) => MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: GestureDetector(
              key: const ValueKey('open'),
              behavior: HitTestBehavior.opaque,
              onTap: () => open(context),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ),
    );

    testWidgets(
      '칸이 비었으면 지금을 분 간격에 맞춰 반올림한 자리를 짚어 열기만 한다 — "완료" 는 그 자리를 넣는다(9시 13분 → 9시 15분)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        PTimeValue? result;
        await tester.pumpWidget(
          opener((context) async {
            result = await showTimePickerSheet(
              context,
              now: DateTime(2026, 10, 15, 9, 13),
            );
          }),
        );
        await tester.tap(find.byKey(const ValueKey('open')));
        await tester.pumpAndSettle();
        expect(_centerLabel(tester, '시'), '9');
        expect(_centerLabel(tester, '분'), '15');
        expect(result, isNull, reason: '열기만 했다 — 고른 것처럼 넣지 않는다');
        await tester.tap(findWidgetWithText(PButton, '완료'));
        await tester.pumpAndSettle();
        expect(result, const PTimeValue(9, 15));
      },
    );

    testWidgets('굴린 값이 "완료" 로 들어가고 · 바깥으로 닫으면 버린다(null)', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      PTimeValue? result = const PTimeValue(1, 1);
      await tester.pumpWidget(
        opener((context) async {
          result = await showTimePickerSheet(
            context,
            current: const PTimeValue(11, 55),
          );
        }),
      );
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      await _tab(tester, 3);
      await _key(tester, LogicalKeyboardKey.arrowDown); // 55 → 00
      await _tab(tester, 3); // 오전·오후 → 시 로 돌아와서
      await tester.tap(findWidgetWithText(PButton, '완료'));
      await tester.pumpAndSettle();
      expect(result, const PTimeValue(11, 0));

      result = const PTimeValue(1, 1);
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      await _tab(tester, 3);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await tester.tapAt(const Offset(180, 20));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('견본', () {
    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 견본이 분 간격 · 막힘 · 날짜 + 시각을 모두 그린다', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: mode == Brightness.dark
                ? GrooTheme.dark()
                : GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: TimePickerDemo(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        expect(find.byType(PTimePicker), findsWidgets);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
