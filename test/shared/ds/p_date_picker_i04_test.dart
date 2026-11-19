// I-04 03-C — 달력의 큰 글자(1B) · 방향키(4A) · 읽는 역할(03C-004).
//
// 큰 글자: 칸 안 글(날짜 숫자 · 요일)은 글자 크기 설정을 따르지 않아 칸 · 요일 줄 48, 원 42 · 이전 · 다음 40 그대로다. 머리 ·
// 이어지는 달 이름 줄만 제목을 따라 48 에서 늘어난다(groo-design #260 · #261).
// 방향키: date-picker.md 키보드 표 그대로 — 날짜 하나만 Tab 순서에 들고, 열 때 초점은 고른 날(없으면 오늘), 링은 키보드일 때만.
// 읽기: 격자는 표(table) · 줄(row) · 칸(cell) · 요일은 columnHeader · 칸 안에 버튼 · 오늘은 이름 끝에 ", 오늘".
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/semantics.dart'
    show SemanticsAction, SemanticsNode, SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/wheel_picker/p_wheel_picker.dart';

final _labels = PDatePickerLabels.ko;
final _today = DateTime(2026, 10, 15);

Widget _app(
  Widget child, {
  double scale = 1,
  double width = 312,
  double? height,
}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, height: height, child: child),
    ),
  ),
);

Finder _day(DateTime d) => find.byKey(ValueKey('date-${dayKey(d)}'));

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// 초점 링이 그려진 날들 — 원(date-day-visual)에 테두리가 있다.
List<String> _ringDays(WidgetTester tester) {
  final out = <String>[];
  for (final e in find.byKey(const ValueKey('date-day-visual')).evaluate()) {
    final box = (e.widget as AnimatedContainer).decoration! as BoxDecoration;
    if (box.border != null) {
      final cell = find.ancestor(
        of: find.byWidget(e.widget),
        matching: find.byType(PDatePickerDayCell),
      );
      out.add(
        dayKey((cell.evaluate().first.widget as PDatePickerDayCell).date),
      );
    }
  }
  return out;
}

/// 의미 트리의 (역할, 이름) 목록.
List<(SemanticsRole, String)> _roles(WidgetTester tester) {
  final out = <(SemanticsRole, String)>[];
  void walk(SemanticsNode n) {
    final data = n.getSemanticsData();
    out.add((data.role, data.label));
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return out;
}

class _Holder extends StatefulWidget {
  const _Holder({
    required this.initial,
    required this.calls,
    this.continuous = false,
    this.max,
  });
  final DateTime? initial;
  final List<DateTime> calls;
  final bool continuous;
  final DateTime? max;

  @override
  State<_Holder> createState() => _HolderState();
}

class _HolderState extends State<_Holder> {
  late DateTime? _v = widget.initial;

  @override
  Widget build(BuildContext context) => PDatePicker.single(
    labels: _labels,
    inset: 0,
    today: _today,
    value: _v,
    max: widget.max,
    visibleRange: widget.continuous
        ? PDateVisibleRange.continuous
        : PDateVisibleRange.month,
    onChanged: (d) {
      widget.calls.add(d);
      setState(() => _v = d);
    },
  );
}

void main() {
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('큰 글자 — 칸 안 글은 그대로, 머리 제목만 커진다(groo-design #260 · #261)', () {
    testWidgets('100% — 머리 48 · 요일 48 · 칸 48 × 6 = 384', (tester) async {
      _viewport(tester, const Size(360, 900));
      await tester.pumpWidget(
        _app(PDatePicker.single(labels: _labels, inset: 0, today: _today)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('date-header'))).height,
        48,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('date-weekdays'))).height,
        48,
      );
      expect(tester.getSize(_day(_today)).height, 48);
      expect(
        tester.getSize(find.byKey(const ValueKey('date-root'))).height,
        384,
      );
    });

    for (final scale in [2.0, 3.0]) {
      testWidgets(
        '글자 ${(scale * 100).round()}% — 요일 48 · 칸 48 × 6 · 원 42 · 이전 · 다음 40 그대로, 칸 안 글은 커지지 않고 제목만 커진다',
        (tester) async {
          _viewport(tester, const Size(360, 900));
          await tester.pumpWidget(
            _app(
              PDatePicker.single(labels: _labels, inset: 0, today: _today),
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // 머리는 제목(22 × 배율)을 따라 48 에서 늘어난다
          final header = math.max(48.0, 22 * scale);
          expect(
            tester.getSize(find.byKey(const ValueKey('date-header'))).height,
            header,
          );
          expect(
            tester.getSize(find.byKey(const ValueKey('date-weekdays'))).height,
            48,
          );
          expect(tester.getSize(_day(_today)).height, 48);
          expect(
            tester.getSize(find.byKey(const ValueKey('date-root'))).height,
            header + 48 + 48 * 6,
          );
          // 날짜 숫자 · 요일 글은 글자 크기 설정을 따르지 않는다(date-picker.md "글자 크기 설정", groo-design #260)
          for (final of in [
            _day(_today),
            find.byKey(const ValueKey('date-weekdays')),
          ]) {
            for (final e
                in find
                    .descendant(of: of, matching: find.byType(RichText))
                    .evaluate()) {
              final rp = e.renderObject! as RenderParagraph;
              expect(rp.textScaler, TextScaler.noScaling);
            }
          }
          // 제목은 커진다
          final titleText = tester.renderObject<RenderParagraph>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('date-title')),
                  matching: find.byType(RichText),
                )
                .first,
          );
          expect(titleText.textScaler.scale(10), closeTo(10 * scale, 0.01));
          // 원은 px — 글자 배율을 따르지 않는다
          expect(
            tester
                .getSize(
                  find.descendant(
                    of: _day(_today),
                    matching: find.byKey(const ValueKey('date-day-visual')),
                  ),
                )
                .width,
            42,
          );
          // 이전 · 다음 40
          final prev = find.bySemanticsLabel('이전 달');
          expect(tester.getSize(prev).width, lessThanOrEqualTo(44));
          // 제목은 한 줄 — 글 높이가 한 줄(22 × 배율) 이하
          final title = tester.renderObject<RenderBox>(
            find.descendant(
              of: find.byKey(const ValueKey('date-title')),
              matching: find.byType(Text),
            ),
          );
          expect(title.size.height, lessThanOrEqualTo(22 * scale + 0.5));
        },
      );
    }

    for (final scale in [2.0, 3.0]) {
      testWidgets(
        '글자 ${(scale * 100).round()}% 이어지는 달 — 칸 48 그대로, 달 이름 줄은 제목처럼 48 에서 글을 따라 늘어난다',
        (tester) async {
          _viewport(tester, const Size(360, 900));
          await tester.pumpWidget(
            _app(
              PDatePicker.single(
                labels: _labels,
                inset: 0,
                today: _today,
                visibleRange: PDateVisibleRange.continuous,
              ),
              scale: scale,
              height: 600,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // 2026년 10월은 5주 — 달 이름 max(48, 22 × 배율) + 5 × 48 + 아래 16(groo-design #261)
          final label = math.max(48.0, 22 * scale);
          final month = find.byKey(
            ValueKey('date-month-${monthNumber(_today)}'),
          );
          expect(tester.getSize(month).height, label + 5 * 48 + 16);
          expect(
            tester
                .getSize(
                  find.descendant(
                    of: month,
                    matching: find.byKey(const ValueKey('date-month-label')),
                  ),
                )
                .height,
            label,
          );
          expect(tester.getSize(_day(_today)).height, 48);
        },
      );
    }

    testWidgets('이어지는 달 — 글자 크기가 바뀌어 달 이름 줄이 늘어나도 보던 달이 맨 위에 남는다', (
      tester,
    ) async {
      _viewport(tester, const Size(360, 900));
      Widget picker(double scale) => _app(
        PDatePicker.single(
          labels: _labels,
          inset: 0,
          today: _today,
          visibleRange: PDateVisibleRange.continuous,
        ),
        scale: scale,
        height: 600,
      );
      final scroll = find.byKey(const ValueKey('date-scroll'));
      final month = find.byKey(ValueKey('date-month-${monthNumber(_today)}'));
      await tester.pumpWidget(picker(1));
      await tester.pumpAndSettle();
      final top = tester.getTopLeft(scroll).dy;
      expect(tester.getTopLeft(month).dy, moreOrLessEquals(top, epsilon: 0.5));
      // 300% — 달 이름 줄 48 → 66, 그 위 달들의 높이가 모두 바뀐다
      await tester.pumpWidget(picker(3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(month).dy,
        moreOrLessEquals(tester.getTopLeft(scroll).dy, epsilon: 0.5),
        reason: '보던 달(2026년 10월)이 다시 맨 위',
      );
    });
  });

  group('연 · 월 휠 높이(I-04 21) — 요일 줄 + 6주', () {
    // 요일 줄 · 칸이 48 그대로라 글자 크기와 상관없이 336(groo-design #260)
    for (final (scale, want) in [(1.0, 336.0), (2.0, 336.0), (3.0, 336.0)]) {
      testWidgets('글자 ${(scale * 100).round()}% → $want', (tester) async {
        _viewport(tester, const Size(360, 900));
        await tester.pumpWidget(
          _app(
            PDatePicker.single(
              labels: _labels,
              inset: 0,
              today: _today,
              defaultWheelOpen: true,
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const ValueKey('date-wheel'))).height,
          want,
        );
      });
    }
  });

  group('보이는 달 — 눌림 색(03-C 2B)', () {
    testWidgets('보통 날은 투명 짝 bg-neutral-weak-alpha-pressed', (tester) async {
      _viewport(tester, const Size(360, 900));
      await tester.pumpWidget(
        _app(PDatePicker.single(labels: _labels, inset: 0, today: _today)),
      );
      await tester.pumpAndSettle();
      final g = await tester.startGesture(
        tester.getCenter(_day(DateTime(2026, 10, 20))),
      );
      await tester.pumpAndSettle();
      final box =
          (tester
                  .widget<AnimatedContainer>(
                    find.descendant(
                      of: _day(DateTime(2026, 10, 20)),
                      matching: find.byKey(const ValueKey('date-day-visual')),
                    ),
                  )
                  .decoration!)
              as BoxDecoration;
      expect(box.color, PColors.light.bgNeutralWeakAlphaPressed);
      await g.up();
    });
  });

  group('방향키(03-C 4A)', () {
    Future<void> open(
      WidgetTester tester, {
      DateTime? initial,
      List<DateTime>? calls,
      bool continuous = false,
      bool keyboard = true,
    }) async {
      _viewport(tester, const Size(360, 900));
      FocusManager.instance.highlightStrategy = keyboard
          ? FocusHighlightStrategy.alwaysTraditional
          : FocusHighlightStrategy.alwaysTouch;
      await tester.pumpWidget(
        _app(
          _Holder(
            initial: initial,
            calls: calls ?? <DateTime>[],
            continuous: continuous,
          ),
          height: continuous ? 600 : null,
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> key(
      WidgetTester tester,
      LogicalKeyboardKey k, {
      bool shift = false,
    }) async {
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(k);
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
    }

    testWidgets('열 때 초점은 고른 날, 없으면 오늘이다', (tester) async {
      await open(tester, initial: DateTime(2026, 10, 3));
      expect(_ringDays(tester), ['2026-10-03']);
      await tester.pumpWidget(const SizedBox());
      await open(tester);
      expect(_ringDays(tester), ['2026-10-15']);
    });

    testWidgets('← → 하루 · ↑ ↓ 한 주 · Home End 그 주의 일 · 토', (tester) async {
      await open(tester);
      await key(tester, LogicalKeyboardKey.arrowRight);
      expect(_ringDays(tester), ['2026-10-16']);
      await key(tester, LogicalKeyboardKey.arrowLeft);
      await key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_ringDays(tester), ['2026-10-14']);
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(_ringDays(tester), ['2026-10-21']);
      await key(tester, LogicalKeyboardKey.arrowUp);
      await key(tester, LogicalKeyboardKey.arrowUp);
      expect(_ringDays(tester), ['2026-10-07']);
      // 2026-10-07 은 수요일 — 그 주의 일요일 10-04 · 토요일 10-10
      await key(tester, LogicalKeyboardKey.home);
      expect(_ringDays(tester), ['2026-10-04']);
      await key(tester, LogicalKeyboardKey.end);
      expect(_ringDays(tester), ['2026-10-10']);
    });

    testWidgets(
      'PageUp · PageDown 한 달(같은 날, 없으면 말일) · Shift 한 해 — 보이는 달이 따라 넘어간다',
      (tester) async {
        await open(tester, initial: DateTime(2026, 1, 31));
        await key(tester, LogicalKeyboardKey.pageDown);
        expect(_ringDays(tester), ['2026-02-28']);
        expect(find.bySemanticsLabel('2026년 2월'), findsWidgets);
        await key(tester, LogicalKeyboardKey.pageUp);
        expect(_ringDays(tester), ['2026-01-28']);
        await key(tester, LogicalKeyboardKey.pageDown, shift: true);
        expect(_ringDays(tester), ['2027-01-28']);
        await key(tester, LogicalKeyboardKey.pageUp, shift: true);
        expect(_ringDays(tester), ['2026-01-28']);
      },
    );

    testWidgets('보이는 달 밖으로 옮기면 달이 따라 넘어간다 — 10월 말에서 →', (tester) async {
      await open(tester, initial: DateTime(2026, 10, 31));
      await key(tester, LogicalKeyboardKey.arrowRight);
      expect(_ringDays(tester), ['2026-11-01']);
      expect(find.byKey(const ValueKey('date-grid-2026-11')), findsOneWidget);
    });

    testWidgets('Enter · Space 는 초점 날을 고른다(막힌 날은 무시)', (tester) async {
      final calls = <DateTime>[];
      await open(tester, initial: DateTime(2026, 10, 3), calls: calls);
      await key(tester, LogicalKeyboardKey.arrowRight);
      await key(tester, LogicalKeyboardKey.enter);
      expect(calls, [DateTime(2026, 10, 4)]);
      await key(tester, LogicalKeyboardKey.arrowRight);
      await key(tester, LogicalKeyboardKey.space);
      expect(calls.last, DateTime(2026, 10, 5));
    });

    testWidgets('날짜 하나만 Tab 순서에 든다 — 격자 안의 초점 자리는 하나', (tester) async {
      await open(tester);
      final grid = find.descendant(
        of: find.byKey(const ValueKey('date-root')),
        matching: find.byWidgetPredicate(
          (w) => w is Focus && w.focusNode?.debugLabel == 'PDatePicker grid',
        ),
      );
      expect(grid, findsOneWidget);
      // 날짜 칸 42개는 초점 자리가 아니다
      final nodes = find.descendant(
        of: find.byKey(const ValueKey('date-grid-2026-10')),
        matching: find.byType(Focus),
      );
      expect(nodes, findsNothing);
    });

    testWidgets('터치 모드에서는 링이 없다 — 키를 눌러 키보드 모드가 되면 그려진다', (tester) async {
      await open(tester, keyboard: false);
      expect(_ringDays(tester), isEmpty);
      await tester.tap(_day(DateTime(2026, 10, 20)));
      await tester.pumpAndSettle();
      expect(_ringDays(tester), isEmpty, reason: '손가락으로 누른 초점에는 링이 없다');
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await key(tester, LogicalKeyboardKey.arrowRight);
      expect(_ringDays(tester), ['2026-10-21'], reason: '눌러 둔 날에서 이어진다');
    });

    testWidgets('이어지는 달 — 초점 날이 보이게 스크롤하고, 12월 말에서 → 는 다음 해로', (tester) async {
      await open(tester, initial: DateTime(2026, 10, 15), continuous: true);
      final scroll = find.byKey(const ValueKey('date-scroll'));
      final before = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      for (var i = 0; i < 12; i++) {
        await key(tester, LogicalKeyboardKey.arrowDown);
      }
      final after = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      expect(after, greaterThan(before), reason: '12주 아래는 화면 밖이라 스크롤이 따라간다');
      expect(_ringDays(tester), ['2027-01-07']);
      // 보이는 날이다
      final rect = tester.getRect(_day(DateTime(2027, 1, 7)));
      final box = tester.getRect(scroll);
      expect(rect.top, greaterThanOrEqualTo(box.top));
      expect(rect.bottom, lessThanOrEqualTo(box.bottom));
    });
  });

  group('읽는 역할(03C-004)', () {
    testWidgets('격자는 표 · 줄 · 칸이고 요일은 열 머리, 칸 안에 버튼 — 오늘은 이름 끝에 ", 오늘"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      _viewport(tester, const Size(360, 900));
      await tester.pumpWidget(
        _app(PDatePicker.single(labels: _labels, inset: 0, today: _today)),
      );
      await tester.pumpAndSettle();
      final roles = _roles(tester);
      expect(
        roles.where((r) => r.$1 == SemanticsRole.table),
        isNotEmpty,
        reason: '표',
      );
      expect(
        roles.where((r) => r.$1 == SemanticsRole.row).length,
        7,
        reason: '요일 줄 1 + 6주',
      );
      expect(
        roles.where((r) => r.$1 == SemanticsRole.columnHeader).map((r) => r.$2),
        _labels.weekdaysLong,
      );
      // 이번 달 31일이 칸
      expect(roles.where((r) => r.$1 == SemanticsRole.cell).length, 31);
      expect(roles.where((r) => r.$2 == '2026년 10월 15일 목요일, 오늘'), hasLength(1));
      expect(
        roles.where((r) => r.$2.endsWith(', 오늘')),
        hasLength(1),
        reason: '오늘만',
      );
      handle.dispose();
    });

    testWidgets('en — 오늘 이름 끝은 ", today"', (tester) async {
      final handle = tester.ensureSemantics();
      _viewport(tester, const Size(360, 900));
      await tester.pumpWidget(
        MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => PDatePicker.single(
                labels: PDatePickerLabels.of(context),
                inset: 0,
                today: _today,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _roles(tester).where((r) => r.$2 == 'Thursday, Oct 15, 2026, today'),
        hasLength(1),
      );
      handle.dispose();
    });

    // 휠 칼럼의 role: spinButton 은 이 Flutter(3.44.9)가 디버그에서 "Missing checks for role" 로 던진다 — 못 넣는다
    // (semantics.dart `_DebugSemanticsRoleChecks`: spinButton => _unimplemented). 칼럼은 지금처럼 조절 가능한 값
    // (이름 · 값 · 올리기 · 내리기)으로 읽힌다.
    testWidgets('연 · 월 휠 칼럼은 이름 있는 조절 가능한 값이다', (tester) async {
      final handle = tester.ensureSemantics();
      _viewport(tester, const Size(360, 900));
      await tester.pumpWidget(
        _app(
          PDatePicker.single(
            labels: _labels,
            inset: 0,
            today: _today,
            defaultWheelOpen: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in ['연도', '월']) {
        final data = tester
            .getSemantics(find.bySemanticsLabel(name))
            .getSemanticsData();
        expect(data.hasAction(SemanticsAction.increase), isTrue, reason: name);
        expect(data.hasAction(SemanticsAction.decrease), isTrue, reason: name);
      }
      handle.dispose();
    });
  });
}
